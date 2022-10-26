// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {ILiquidateFacet} from "../interfaces/ILiquidateFacet.sol";
import {LibLoan} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibAppStorage, AppStorage, Storage, BorrowData, BorrowState, Loan, ReserveConfigurationMap, ReserveData, PMT} from "../libraries/LibAppStorage.sol";
import {ExecuteLiquidateParams} from "../libraries/LibLoan.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";

contract LiquidateFacet is Storage, ReentrancyGuard, ILiquidateFacet {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    event Liquidate(
        address indexed _liquidator,
        address indexed _vault,
        address indexed _collection,
        uint256 _drowDownId,
        uint256 _repaymentId,
        uint256 _debt,
        uint256 _fromJuniorTranche,
        uint256 _amountToWriteDown
    );

    function liquidate(
        address _collection,
        address _vault,
        uint256 _loanId
    ) external whenNotPaused nonReentrant {
        ExecuteLiquidateParams memory param;
        param.collection = _collection;
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            param.collection
        );
        param.currency = reserveData.currency;
        ReserveConfigurationMap memory reserveConf = LibReserveConfiguration
            .getConfiguration(param.collection);

        // 1. prepare basic info and some strategy parameters
        param.vault = _vault;
        param.loanId = _loanId;
        param.liquidator = _msgSender();

        BorrowData storage borrowData = LibLoan.getBorrowData(
            param.collection,
            param.currency,
            param.vault
        );

        LibLoan.LoanDetail memory loanDetail = LibLoan.getLoanDetail(
            borrowData,
            param.currency,
            param.loanId
        );

        // 2. check if the debt is qualified to be liquidated
        {
            uint256 gracePeriod;
            (param.liquidationBonus, gracePeriod) = reserveConf
                .getLiquidationParams();
            if (
                block.timestamp <= loanDetail.nextPaymentDue ||
                block.timestamp - loanDetail.nextPaymentDue <=
                gracePeriod * LibLoan.SECOND_PER_DAY
            ) {
                revert InvalidLiquidate();
            }
        }

        // 3. get floor price from oracle contract
        {
            IPriceOracle priceOracle = IPriceOracle(
                reserveData.priceOracle.implementation()
            );

            (uint256 floorPrice, uint256 floorPriceTime) = priceOracle.getTwap(
                param.collection
            );

            if (
                (block.timestamp - floorPriceTime) >
                reserveConf.getMaxTwapStaleness()
            ) {
                revert LiquidateStaleTwap();
            }

            if (floorPrice == 0) {
                revert InvalidLiquidateFloorPrice();
            }

            // 4. get remaining debt info
            (
                param.remainingPrincipal,
                param.remainingInterest,
                param.remainingFee,
                param.incomeRatio
            ) = LibLoan.getRemainingDebt(
                param.collection,
                param.currency,
                param.vault,
                param.loanId
            );
            param.totalDebt = param.remainingPrincipal;
            if (param.totalDebt == 0) {
                revert InvalidLiquidateDebt();
            }
            uint256 discount = getDiscount(floorPrice, param.liquidationBonus);
            uint256 discountedFloorPrice = floorPrice - discount;

            // 5. transfer all nfts to liquidator
            uint256[] memory collaterals = LibLoan.releaseLien(
                param.collection,
                param.currency,
                param.vault,
                param.loanId
            );

            param.collateralVaule = discountedFloorPrice * collaterals.length;

            IERC20(param.currency).safeTransferFrom(
                param.liquidator,
                address(this),
                param.collateralVaule
            );

            LibLoan.transferCollateral(
                collaterals,
                param.collection,
                param.liquidator,
                param.vault
            );
        }

        BorrowState storage borrowState = LibLoan.getBorrowState(
            param.collection,
            reserveData.currency
        );
        // 6. if collaterals cannot cover debt
        if (param.totalDebt > param.collateralVaule) {
            // repay senior tranche principal and writedown
            uint256 remainingDebt = param.totalDebt - param.collateralVaule;
            uint256 totalLiquidityFromJuniorTranche = IERC20(param.currency)
                .balanceOf(reserveData.juniorDepositTokenAddress);

            if (totalLiquidityFromJuniorTranche >= remainingDebt) {
                IVToken(reserveData.juniorDepositTokenAddress)
                    .transferUnderlyingTo(address(this), remainingDebt);
                IERC20(param.currency).safeTransfer(
                    reserveData.seniorDepositTokenAddress,
                    param.totalDebt
                );
                param.juniorTrancheAmount = remainingDebt;
                borrowState.totalDebt -= param.totalDebt;
            } else {
                IVToken(reserveData.juniorDepositTokenAddress)
                    .transferUnderlyingTo(
                        address(this),
                        totalLiquidityFromJuniorTranche
                    );
                IERC20(param.currency).safeTransfer(
                    reserveData.seniorDepositTokenAddress,
                    param.collateralVaule + totalLiquidityFromJuniorTranche
                );
                param.juniorTrancheAmount = totalLiquidityFromJuniorTranche;
                borrowState.totalDebt -=
                    param.collateralVaule +
                    totalLiquidityFromJuniorTranche;

                param.writeDownAmount =
                    remainingDebt -
                    totalLiquidityFromJuniorTranche;
                LibLoan.writedownSeniorPrincipal(
                    borrowState,
                    param.writeDownAmount
                );
            }

            // writedown senior intereset and junior interest
            {
                (
                    uint256 outstandingSeniorInterest,
                    uint256 outstandingJuniorInterest
                ) = LibLoan.getInterest(
                        reserveData,
                        param.remainingInterest,
                        param.incomeRatio
                    );
                LibLoan.writedownSeniorInterest(
                    borrowState,
                    outstandingSeniorInterest
                );
                LibLoan.writedownJuniorInterest(
                    borrowState,
                    outstandingJuniorInterest
                );
            }
        } else {
            // 7. if collaterals can cover debt

            // repay senior tranche principal
            IERC20(param.currency).safeTransfer(
                reserveData.seniorDepositTokenAddress,
                param.totalDebt
            );
            borrowState.totalDebt -= param.totalDebt;

            uint256 availableFunds = param.collateralVaule - param.totalDebt;
            {
                (
                    uint256 outstandingSeniorInterest,
                    uint256 outstandingJuniorInterest
                ) = LibLoan.getInterest(
                        reserveData,
                        param.remainingInterest,
                        param.incomeRatio
                    );

                // try to repay senior tranche interest
                (param.reducedAmount, param.writedownAmount) = LibLoan.tryRepay(
                    availableFunds,
                    outstandingSeniorInterest,
                    param.currency,
                    reserveData.seniorDepositTokenAddress
                );

                availableFunds -= param.reducedAmount;
                borrowState.totalSeniorInterest -= param.reducedAmount;
                borrowState.totalInterest -= param.reducedAmount;
                // writedown senior interest
                if (param.writedownAmount != 0) {
                    LibLoan.writedownSeniorInterest(
                        borrowState,
                        param.writedownAmount
                    );
                    param.writedownAmount = 0;
                }
                // try to repay junior tranche interesst
                (param.reducedAmount, param.writedownAmount) = LibLoan.tryRepay(
                    availableFunds,
                    outstandingJuniorInterest,
                    param.currency,
                    reserveData.juniorDepositTokenAddress
                );
                availableFunds -= param.reducedAmount;
                borrowState.totalJuniorInterest -= param.reducedAmount;
                borrowState.totalInterest -= param.reducedAmount;

                // writedown junior interest
                if (param.writedownAmount != 0) {
                    LibLoan.writedownJuniorInterest(
                        borrowState,
                        param.writedownAmount
                    );
                    param.writedownAmount = 0;
                }
            }

            (uint256 takeRate, address treasury) = LibLiquidity
                .getTakeRateAndTreasuryAddr();

            // try to repay protocol fee
            (param.reducedAmount, param.writedownAmount) = LibLoan.tryRepay(
                availableFunds,
                param.remainingFee,
                param.currency,
                treasury
            );
            availableFunds -= param.reducedAmount;

            // transfer back to vault
            if (availableFunds > 0) {
                IERC20(param.currency).safeTransfer(
                    param.vault,
                    availableFunds
                );
            }
        }

        // 7. record repay info
        LibLoan.closeDebt(
            param.collection,
            param.currency,
            param.vault,
            param.loanId
        );

        // 8. slash Rep
        LibVault.slashRep(param.vault, param.collection, param.currency);

        emit Liquidate(
            param.liquidator,
            param.vault,
            param.currency,
            param.loanId,
            param.repaymentId,
            param.totalDebt,
            param.juniorTrancheAmount,
            param.writeDownAmount
        );
    }

    function getDiscount(uint256 _value, uint256 _liquidationBonus)
        private
        pure
        returns (uint256)
    {
        uint256 withBonus = _value.percentMul(_liquidationBonus);
        return withBonus - _value;
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidLiquidate();
error InvalidLiquidateFloorPrice();
error LiquidateStaleTwap();
error InvalidLiquidateDebt();

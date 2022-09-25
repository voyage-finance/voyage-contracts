// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibLoan, ExecuteBuyNowParams, ExecuteLiquidateParams} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibMarketplace} from "../libraries/LibMarketplace.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {AssetInfo} from "../interfaces/IMarketPlaceAdapter.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {LibAppStorage, AppStorage, Storage, BorrowData, BorrowState, Loan, ReserveConfigurationMap, ReserveData, PMT} from "../libraries/LibAppStorage.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {LibPayments} from "../../shared/libraries/LibPayments.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {SafeTransferLib} from "../../shared/libraries/SafeTransferLib.sol";
import {IVault} from "../../vault/Vault.sol";
import {IUnbondingToken} from "../tokenization/SeniorDepositToken.sol";

contract LoanFacet is Storage, ReentrancyGuard {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    uint256 public immutable TEN_THOUSANDS = 10000;

    struct ExecuteRepayParams {
        address vault;
        uint256 principal;
        uint256 interest;
        uint256 fee;
        uint256 total;
        uint256 totalDebt;
        uint256 incomeRatio;
        uint256 takeRate;
        address treasury;
    }

    struct PreviewBuyNowParams {
        uint256 epoch;
        uint256 term;
        uint256 nper;
        uint256 totalPrincipal;
        uint256 totalInterest;
        uint256 borrowRate;
        uint256 takeRate;
        uint256 protocolFee;
        uint256 loanId;
        PMT pmt;
    }

    event Borrow(
        address indexed _vault,
        address indexed _collection,
        address indexed _currency,
        uint256 _tokenId,
        uint256 _loanId,
        uint256 _principal,
        uint256 _interest,
        uint256 _apr,
        uint256 _protocolFee,
        address _marketplace
    );

    event Repayment(
        address indexed _user,
        address indexed _vault,
        address indexed _collection,
        address _currency,
        uint256 _loanId,
        uint256 _repaymentId,
        uint256 _amount,
        bool isFinal
    );

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

    function previewBuyNowParams(
        address _collection,
        address _vault,
        uint256 _principal
    ) public view returns (PreviewBuyNowParams memory) {
        PreviewBuyNowParams memory params;
        params.totalPrincipal = _principal;
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );
        BorrowData storage borrowData = LibLoan.getBorrowData(
            _collection,
            reserveData.currency,
            _vault
        );
        params.loanId = borrowData.nextLoanNumber;
        ReserveConfigurationMap memory reserveConf = LibReserveConfiguration
            .getConfiguration(_collection);

        (params.epoch, params.term) = reserveConf.getBorrowParams();
        params.nper = params.term / params.epoch;

        uint256 outstandingPrincipal = params.totalPrincipal -
            params.totalPrincipal /
            params.nper;

        BorrowState storage borrowState = LibLoan.getBorrowState(
            _collection,
            reserveData.currency
        );

        (params.borrowRate) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateBorrowRate(
                reserveData.currency,
                reserveData.seniorDepositTokenAddress,
                0,
                outstandingPrincipal,
                borrowState.totalDebt
            );

        params.totalInterest = LibLoan.previewInterest(
            params.totalPrincipal,
            params.borrowRate,
            params.epoch,
            params.nper
        );

        params.takeRate = LibAppStorage.ds().protocolFee.takeRate;
        params.protocolFee = params.totalPrincipal.percentMul(params.takeRate);

        params.pmt = LibLoan.previewPMT(
            params.totalPrincipal,
            params.totalInterest,
            params.protocolFee,
            params.nper
        );

        return params;
    }

    function buyNow(
        address _collection,
        uint256 _tokenId,
        address payable _vault,
        address _marketplace,
        bytes calldata _data
    ) external whenNotPaused nonReentrant {
        ExecuteBuyNowParams memory params;
        params.collection = _collection;
        params.tokenId = _tokenId;
        params.vault = _vault;
        params.marketplace = _marketplace;
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            params.collection
        );

        params.currency = reserveData.currency;

        BorrowState storage borrowState = LibLoan.getBorrowState(
            params.collection,
            reserveData.currency
        );

        BorrowData storage borrowData = LibLoan.getBorrowData(
            params.collection,
            params.currency,
            params.vault
        );

        params.totalOutstandingDebt = borrowData.totalPrincipal;

        // 0. check if the user owns the vault
        if (LibVault.getVaultAddress(_msgSender()) != params.vault) {
            revert Unauthorised();
        }

        // 1. get price for params.tokenId  and floor price pv
        params.assetInfo = LibMarketplace.extractAssetInfo(_marketplace, _data);
        params.totalPrincipal = params.assetInfo.assetPrice;
        if (params.tokenId != params.assetInfo.tokenId) {
            revert InvalidTokenid();
        }
        (params.fv, params.timestamp) = IPriceOracle(
            reserveData.priceOracle.implementation()
        ).getTwap(params.collection);

        ReserveConfigurationMap memory reserveConf = LibReserveConfiguration
            .getConfiguration(params.collection);
        if (
            (block.timestamp - params.timestamp) >
            reserveConf.getMaxTwapStaleness()
        ) {
            revert BuyNowStaleTwap();
        }

        if (params.fv == 0) {
            revert InvalidFloorPrice();
        }

        if (params.fv < params.totalPrincipal) {
            revert ExceedsFloorPrice();
        }

        // 2. get borrow params and borrow rate

        (params.epoch, params.term) = reserveConf.getBorrowParams();
        params.nper = params.term / params.epoch;
        params.outstandingPrincipal =
            params.totalPrincipal -
            params.totalPrincipal /
            params.nper;

        // 3.0 get liquidity of senior tranche and junior tranche
        params.totalSeniorBalance = IERC20(reserveData.currency).balanceOf(
            reserveData.seniorDepositTokenAddress
        );

        params.totalJuniorBalance = IERC20(reserveData.currency).balanceOf(
            reserveData.juniorDepositTokenAddress
        );

        // 3.1 junior tranche cannot be 0
        if (params.totalJuniorBalance == 0) {
            revert InvalidJuniorTrancheBalance();
        }

        if (
            params.totalJuniorBalance.percentDiv(
                reserveConf.getOptimalLiquidityRatio()
            ) < params.outstandingPrincipal
        ) {
            revert InsufficientJuniorLiquidity();
        }

        // 3.2 check if available liquidity sufficient
        params.totalPending = IUnbondingToken(
            reserveData.seniorDepositTokenAddress
        ).totalUnbondingAsset();

        if (params.totalPending >= params.totalSeniorBalance) {
            revert InsufficientCash();
        }
        params.availableLiquidity =
            params.totalSeniorBalance -
            params.totalPending;

        if (params.availableLiquidity < params.outstandingPrincipal) {
            revert InsufficientLiquidity();
        }

        (params.borrowRate) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateBorrowRate(
                reserveData.currency,
                reserveData.seniorDepositTokenAddress,
                0,
                params.outstandingPrincipal,
                borrowState.totalDebt
            );

        // 4. insert debt, get total interest and PMT
        params.incomeRatio = LibReserveConfiguration
            .getConfiguration(params.collection)
            .getIncomeRatio();
        (params.takeRate, params.treasury) = LibLiquidity
            .getTakeRateAndTreasuryAddr();
        (params.loanId, params.pmt, params.totalInterest, params.fee) = LibLoan
            .initDebt(borrowState, borrowData, params);

        // 5. calculate downpayment and outstanding interest and debt
        params.downpayment = params.pmt.principal;
        params.outstandingInterest = params.totalInterest - params.pmt.interest;

        // 6. check credit limit against with outstanding debt
        params.maxCreditLimit = LibVault.getCreditLimit(
            params.vault,
            params.collection,
            reserveData.currency,
            params.fv
        );

        if (params.maxCreditLimit < params.totalOutstandingDebt) {
            revert InsufficientMaxCreditLimit();
        }

        params.availableCreditLimit =
            params.maxCreditLimit -
            params.totalOutstandingDebt;

        if (params.availableCreditLimit < params.outstandingPrincipal) {
            revert InsufficientCreditLimit();
        }

        if (
            IERC20(reserveData.currency).balanceOf(params.vault) <
            params.downpayment
        ) {
            revert InsufficientVaultBalance();
        }

        // 7. transfer money to this
        IVToken(reserveData.seniorDepositTokenAddress).transferUnderlyingTo(
            address(this),
            params.outstandingPrincipal
        );

        // 8. distrubute interest and protocol fee before unwrap weth to eth
        LibLoan.distributeInterest(
            reserveData,
            params.pmt.interest,
            params.vault,
            params.incomeRatio
        );

        LibLoan.distributeProtocolFee(
            reserveData,
            params.pmt.fee,
            params.vault,
            params.treasury
        );

        (params.pmt.principal, params.pmt.interest, params.pmt.fee) = LibLoan
            .getPMT(
                params.collection,
                reserveData.currency,
                params.vault,
                params.loanId
            );

        // 9.1 if currency is eth
        if (params.assetInfo.currency == address(0)) {
            LibPayments.unwrapWETH9(params.outstandingPrincipal, address(this));
            SafeTransferLib.safeTransferETH(
                params.vault,
                params.outstandingPrincipal
            );
            LibMarketplace.purchase(
                params.marketplace,
                params.vault,
                params.totalPrincipal,
                _data
            );
        } else {
            // 9.2 if currency is weth
            IERC20(LibAppStorage.ds().WETH9).safeTransfer(
                params.vault,
                params.outstandingPrincipal
            );

            LibMarketplace.purchase(params.marketplace, params.vault, 0, _data);
        }

        // 10. first payment
        BorrowData storage debtData = LibLoan.getBorrowData(
            params.collection,
            reserveData.currency,
            params.vault
        );
        LibLoan.firstRepay(
            borrowState,
            debtData,
            params.loanId,
            params.incomeRatio
        );

        emit Borrow(
            params.vault,
            params.collection,
            reserveData.currency,
            params.tokenId,
            params.loanId,
            params.totalPrincipal,
            params.totalInterest,
            params.borrowRate,
            params.fee,
            params.marketplace
        );
    }

    function repay(
        address _collection,
        uint256 _loan,
        address payable _vault
    ) external whenNotPaused nonReentrant {
        ExecuteRepayParams memory params;
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );

        // 0. check if the user owns the vault
        if (LibVault.getVaultAddress(_msgSender()) != _vault) {
            revert Unauthorised();
        }

        params.vault = _vault;

        // 1. check draw down to get principal and interest
        (params.principal, params.interest, params.fee) = LibLoan.getPMT(
            _collection,
            reserveData.currency,
            _vault,
            _loan
        );
        if (params.principal + params.interest == 0) {
            revert InvalidDebt();
        }

        params.total = params.principal + params.interest;
        params.incomeRatio = LibLoan.getIncomeRatio(
            _collection,
            reserveData.currency,
            _vault,
            _loan
        );
        (params.takeRate, params.treasury) = LibLiquidity
            .getTakeRateAndTreasuryAddr();

        // 2. update repay data
        (uint256 repaymentId, bool isFinal) = LibLoan.repay(
            _collection,
            reserveData.currency,
            _vault,
            _loan
        );

        // 3. distribute interest
        LibLoan.distributeInterest(
            reserveData,
            params.interest,
            params.vault,
            params.incomeRatio
        );

        // 4. distribute fee
        LibLoan.distributeProtocolFee(
            reserveData,
            params.fee,
            params.vault,
            params.treasury
        );

        IERC20(reserveData.currency).safeTransferFrom(
            params.vault,
            reserveData.seniorDepositTokenAddress,
            params.principal
        );

        emit Repayment(
            _msgSender(),
            _vault,
            _collection,
            reserveData.currency,
            _loan,
            repaymentId,
            params.total,
            isFinal
        );
    }

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
                revert InvalidFloorPrice();
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
                revert InvalidDebt();
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

    function getVaultDebt(address _collection, address _vault)
        public
        view
        returns (uint256, uint256)
    {
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );
        return LibVault.getVaultDebt(_collection, reserveData.currency, _vault);
    }

    /// @notice Returns the total outstanding principal debt for a particular underlying asset pool
    /// @param _collection the address of the underlying nft collection.
    /// @return The total outstanding principal owed to depositors.
    function principalBalance(address _collection)
        external
        view
        returns (uint256)
    {
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );
        BorrowState storage borrowState = LibLoan.getBorrowState(
            _collection,
            reserveData.currency
        );
        return borrowState.totalDebt;
    }

    /// @notice Returns the total outstanding interest debt for a particular underlying asset pool
    /// @param _collection the address of the underlying nft collection.
    /// @return The total outstanding interest owed to depositors.
    function interestBalance(address _collection)
        external
        view
        returns (uint256)
    {
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );
        BorrowState storage borrowState = LibLoan.getBorrowState(
            _collection,
            reserveData.currency
        );
        return borrowState.totalInterest;
    }

    function seniorInterestBalance(address _collection, address _asset)
        external
        view
        returns (uint256)
    {
        BorrowState storage borrowState = LibLoan.getBorrowState(
            _collection,
            _asset
        );
        return borrowState.totalSeniorInterest;
    }

    function juniorInterestBalance(address _collection, address _asset)
        external
        view
        returns (uint256)
    {
        BorrowState storage borrowState = LibLoan.getBorrowState(
            _collection,
            _asset
        );
        return borrowState.totalJuniorInterest;
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
error Unauthorised();
error InsufficientCash();
error InsufficientLiquidity();
error InsufficientJuniorLiquidity();
error InsufficientVaultBalance();
error InsufficientMaxCreditLimit();
error InsufficientCreditLimit();
error InvalidDebt();
error InvalidLiquidate();
error InvalidFloorPrice();
error InvalidTokenid();
error InvalidPrincipal();
error InvalidJuniorTrancheBalance();
error ExceedsFloorPrice();
error BuyNowStaleTwap();
error LiquidateStaleTwap();

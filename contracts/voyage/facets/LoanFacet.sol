// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibLoan} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {LibAppStorage, AppStorage, Storage, BorrowData, BorrowState, Loan, ReserveConfigurationMap, ReserveData} from "../libraries/LibAppStorage.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {VaultDataFacet} from "../../vault/facets/VaultDataFacet.sol";
import {VaultAssetFacet} from "../../vault/facets/VaultAssetFacet.sol";

contract LoanFacet is Storage {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    uint256 public immutable TEN_THOUSANDS = 10000;

    struct ExecuteBorrowParams {
        address collection;
        uint256 tokenId;
        address vault;
        uint256 totalLoan;
        uint256 term;
        uint256 epoch;
        uint256 nper;
        uint256 initialPay;
        uint256 borrowedVaule;
        uint256 liquidityRate;
        uint256 borrowRate;
        uint256 availableLiquidity;
        uint256 totalBalance;
        uint256 totalPending;
        uint256 loanId;
        uint256 principal;
        uint256 interest;
    }

    struct ExecuteLiquidateParams {
        address collection;
        address currency;
        address vault;
        uint256 loanId;
        uint256 repaymentId;
        uint256 principal;
        uint256 interest;
        uint256 totalDebt;
        uint256 remaningDebt;
        uint256 discount;
        uint256 discountedFloorPrice;
        uint256 amountNeedExtra;
        uint256 juniorTrancheAmount;
        uint256 receivedAmount;
        address liquidator;
        uint256 floorPrice;
        uint256 floorPriceTime;
        uint256 gracePeriod;
        uint256 liquidationBonus;
        uint256 marginRequirement;
        uint256 writeDownAmount;
        uint256 totalAssetFromJuniorTranche;
        bool isFinal;
    }

    struct ExecuteRepayParams {
        uint256 principal;
        uint256 interest;
        uint256 total;
        uint256 totalDebt;
    }

    event Borrow(
        address indexed _vault,
        address indexed _collection,
        address indexed _currency,
        uint256 _loanId,
        uint256 _principal,
        uint256 _interest,
        uint256 _apr
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

    event CollateralTransferred(address from, address to);

    function buyNow(
        address _collection,
        uint256 _tokenId,
        address payable _vault
    ) external payable whenNotPaused {
        ExecuteBorrowParams memory params;
        params.collection = _collection;
        params.tokenId = _tokenId;
        params.vault = _vault;

        // 0. check if the user owns the vault
        if (LibVault.getVaultAddress(_msgSender()) != params.vault) {
            revert Unauthorised();
        }

        ReserveData memory reserveData = LibLiquidity.getReserveData(
            params.collection
        );

        // 1. get price for params.tokenId  and floor price pv
        params.totalLoan = getAssetPrice(params.collection, params.tokenId);
        uint256 fv = getFloorPrice(params.collection);

        // 2. calculate money to pay for the first time, and money to borrow
        ReserveConfigurationMap memory reserveConf = LibReserveConfiguration
            .getConfiguration(params.collection);
        (params.epoch, params.term) = reserveConf.getBorrowParams();
        params.nper = params.term / params.epoch;
        params.initialPay = params.totalLoan / params.nper;
        params.borrowedVaule = params.totalLoan - params.initialPay;

        // 3. check credit limit
        uint256 availableCreditLimit = LibVault.getCreditLimit(
            params.vault,
            params.collection,
            reserveData.currency,
            fv
        );

        if (availableCreditLimit < params.borrowedVaule) {
            revert InsufficientCreditLimit();
        }

        // 4. check if pool liquidity is sufficient
        params.totalPending = IVToken(reserveData.seniorDepositTokenAddress)
            .totalUnbonding();
        params.totalBalance = IERC20(reserveData.currency).balanceOf(
            reserveData.seniorDepositTokenAddress
        );
        if (params.totalBalance > params.totalPending) {
            params.availableLiquidity =
                params.totalBalance -
                params.totalPending;
        }

        if (params.availableLiquidity < params.borrowedVaule) {
            revert InsufficientLiquidity();
        }

        BorrowState storage borrowState = LibLoan.getBorrowState(
            params.collection,
            reserveData.currency
        );

        (
            params.liquidityRate,
            params.borrowRate
        ) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateInterestRates(
                reserveData.currency,
                reserveData.seniorDepositTokenAddress,
                0,
                params.totalLoan,
                borrowState.totalDebt,
                borrowState.avgBorrowRate
            );

        // 5. record debt info
        (uint256 loanId, Loan memory loan) = LibLoan.insertDebt(
            params.collection,
            reserveData.currency,
            params.tokenId,
            params.vault,
            params.totalLoan,
            params.term,
            params.epoch,
            params.borrowRate
        );

        // 6. receive first payment
        if (params.initialPay > msg.value) {
            IERC20(reserveData.currency).safeTransferFrom(
                msg.sender,
                address(this),
                (params.initialPay - msg.value)
            );
        } else {
            if (params.initialPay != msg.value) {
                revert InvalidValueTransfered();
            }
        }

        // 7. todo purchase nft
        (params.principal, params.interest) = LibLoan.getPMT(
            params.collection,
            reserveData.currency,
            params.vault,
            params.loanId
        );

        // 8. first payment
        LibLoan.repay(
            params.collection,
            reserveData.currency,
            params.vault,
            loanId,
            params.principal,
            params.interest
        );

        emit Borrow(
            params.vault,
            params.collection,
            reserveData.currency,
            loanId,
            loan.principal,
            loan.interest,
            loan.apr
        );
    }

    function repay(
        address _collection,
        uint256 _loan,
        address payable _vault
    ) external whenNotPaused {
        ExecuteRepayParams memory params;
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );

        // 0. check if the user owns the vault
        if (LibVault.getVaultAddress(_msgSender()) != _vault) {
            revert Unauthorised();
        }

        // 1. check draw down to get principal and interest
        (params.principal, params.interest) = LibLoan.getPMT(
            _collection,
            reserveData.currency,
            _vault,
            _loan
        );
        if (params.principal + params.interest == 0) {
            revert InvalidDebt();
        }

        params.total = params.principal + params.interest;

        // 2. update repay data
        (uint256 repaymentId, bool isFinal) = LibLoan.repay(
            _collection,
            reserveData.currency,
            _vault,
            _loan,
            params.principal,
            params.interest
        );

        // 3. transfer underlying asset
        uint256 incomeRatio = LibReserveConfiguration
            .getConfiguration(reserveData.currency)
            .getIncomeRatio();
        uint256 seniorInterest = params.interest.percentMul(incomeRatio);

        IERC20(reserveData.currency).safeTransferFrom(
            _msgSender(),
            reserveData.seniorDepositTokenAddress,
            params.principal + seniorInterest
        );

        IERC20(reserveData.currency).safeTransferFrom(
            _msgSender(),
            reserveData.juniorDepositTokenAddress,
            params.interest - seniorInterest
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
    ) external whenNotPaused {
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
        (
            param.liquidationBonus,
            param.marginRequirement,
            param.gracePeriod
        ) = reserveConf.getLiquidationParams();

        LibLoan.LoanDetail memory loanDetail = LibLoan.getLoanDetail(
            param.collection,
            param.currency,
            param.vault,
            param.loanId
        );

        // 2. check if the debt is qualified to be liquidated
        if (
            block.timestamp <= loanDetail.nextPaymentDue ||
            block.timestamp - loanDetail.nextPaymentDue <=
            param.gracePeriod * LibLoan.SECOND_PER_DAY
        ) {
            revert InvalidLiquidate();
        }

        // 3.1 if it is, get debt info
        (param.principal, param.interest) = LibLoan.getPMT(
            param.collection,
            param.currency,
            param.vault,
            param.loanId
        );
        param.totalDebt = param.principal + param.interest;
        param.remaningDebt = param.totalDebt;
        param.discount = getDiscount(param.totalDebt, param.liquidationBonus);
        param.discountedFloorPrice = param.totalDebt - param.discount;

        // 3.2 get floor price from oracle contract
        IPriceOracle priceOracle = IPriceOracle(reserveData.priceOracle);
        (param.floorPrice, param.floorPriceTime) = priceOracle.getTwap(
            param.collection
        );

        if (param.floorPrice == 0) {
            revert InvalidFloorPrice();
        }

        // 4.3 sell nft
        while (param.remaningDebt > 0) {
            (bool success, uint256 tokenId) = LibLoan.removeCollateral(
                param.collection,
                param.currency,
                param.vault,
                param.loanId
            );
            if (success) {
                IERC20(param.currency).safeTransferFrom(
                    param.liquidator,
                    address(this),
                    param.discountedFloorPrice
                );
                VaultAssetFacet(param.vault).transferNFT(
                    param.collection,
                    param.liquidator,
                    tokenId
                );
                if (param.remaningDebt > param.discountedFloorPrice) {
                    param.remaningDebt =
                        param.remaningDebt -
                        param.discountedFloorPrice;
                    param.receivedAmount += param.discountedFloorPrice;
                } else {
                    param.remaningDebt = 0;
                    // refund to vault
                    uint256 refundAmount = param.discountedFloorPrice -
                        param.remaningDebt;
                    IERC20(param.currency).transfer(param.vault, refundAmount);
                    param.receivedAmount += param.remaningDebt;
                }
            } else {
                break;
            }
        }

        emit CollateralTransferred(param.vault, param.liquidator);

        // 4.4 transfer from junior tranche
        param.totalAssetFromJuniorTranche = ERC4626(
            reserveData.juniorDepositTokenAddress
        ).totalAssets();

        uint256 remaningDebt = param.discount + param.remaningDebt;

        if (param.totalAssetFromJuniorTranche >= remaningDebt) {
            IVToken(reserveData.juniorDepositTokenAddress).transferUnderlyingTo(
                    address(this),
                    remaningDebt
                );
            param.juniorTrancheAmount = remaningDebt;
            param.receivedAmount += remaningDebt;
        } else {
            IVToken(reserveData.juniorDepositTokenAddress).transferUnderlyingTo(
                    address(this),
                    param.totalAssetFromJuniorTranche
                );
            param.juniorTrancheAmount = param.totalAssetFromJuniorTranche;
            param.receivedAmount += param.totalAssetFromJuniorTranche;
            param.writeDownAmount =
                remaningDebt -
                param.totalAssetFromJuniorTranche;
        }

        (param.repaymentId, param.isFinal) = LibLoan.repay(
            param.collection,
            param.currency,
            param.vault,
            param.loanId,
            param.principal,
            param.interest
        );

        emit Repayment(
            _msgSender(),
            param.vault,
            param.collection,
            param.currency,
            param.loanId,
            param.repaymentId,
            param.totalDebt,
            param.isFinal
        );

        IERC20(param.currency).safeTransfer(
            reserveData.seniorDepositTokenAddress,
            param.receivedAmount
        );

        emit Liquidate(
            _msgSender(),
            _vault,
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

    function getDiscount(uint256 _value, uint256 _liquidationBonus)
        private
        pure
        returns (uint256)
    {
        uint256 withBonus = _value.percentMul(_liquidationBonus);
        return withBonus - _value;
    }

    function getAssetPrice(address _collection, uint256 _tokenId)
        private
        returns (uint256)
    {
        // todo get from market place
        return 0;
    }

    function getFloorPrice(address _collection) private returns (uint256) {
        // todo get floor price from oracle
        return 0;
    }
}

/* --------------------------------- errors -------------------------------- */
error Unauthorised();
error InsufficientLiquidity();
error InsufficientCreditLimit();
error InvalidDebt();
error InvalidLiquidate();
error InvalidFloorPrice();
error InvalidValueTransfered();

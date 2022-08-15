// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibLoan} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {LibAppStorage, AppStorage, Storage, BorrowData, BorrowState, Loan, ReserveConfigurationMap, ReserveData, PMT} from "../libraries/LibAppStorage.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {PaymentsFacet} from "../../shared/facets/PaymentsFacet.sol";
import {SafeTransferLib} from "../../shared/libraries/SafeTransferLib.sol";
import {IVault} from "../../vault/Vault.sol";
import {MarketplaceAdapterFacet} from "./MarketplaceAdapterFacet.sol";
import "hardhat/console.sol";

contract LoanFacet is Storage {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    uint256 public immutable TEN_THOUSANDS = 10000;

    struct ExecuteBuyNowParams {
        address collection;
        address marketplace;
        uint256 tokenId;
        address vault;
        uint256 totalPrincipal;
        uint256 totalInterest;
        uint256 totalDebt;
        uint256 outstandingPrincipal;
        uint256 outstandingInterest;
        uint256 outstandingDebt;
        uint256 fv;
        uint256 timestamp;
        uint256 term;
        uint256 epoch;
        uint256 nper;
        uint256 downpayment;
        uint256 liquidityRate;
        uint256 borrowRate;
        uint256 availableLiquidity;
        uint256 totalBalance;
        uint256 totalPending;
        uint256 loanId;
        PMT pmt;
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

    event CollateralTransferred(
        address collection,
        address from,
        address to,
        uint256[] collaterals
    );

    function previewBuyNowParams(address _collection, uint256 _amount)
        public
        view
        returns (ExecuteBuyNowParams memory)
    {
        ExecuteBuyNowParams memory executeBorrowParams;
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );
        ReserveConfigurationMap memory reserveConf = LibReserveConfiguration
            .getConfiguration(_collection);

        (executeBorrowParams.epoch, executeBorrowParams.term) = reserveConf
            .getBorrowParams();

        BorrowState storage borrowState = LibLoan.getBorrowState(
            _collection,
            reserveData.currency
        );

        (
            executeBorrowParams.liquidityRate,
            executeBorrowParams.borrowRate
        ) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateInterestRates(
                reserveData.currency,
                reserveData.seniorDepositTokenAddress,
                0,
                _amount,
                borrowState.totalDebt,
                borrowState.avgBorrowRate
            );

        return executeBorrowParams;
    }

    function buyNow(
        address _collection,
        uint256 _tokenId,
        address payable _vault,
        address _marketplace,
        bytes calldata _data
    ) external payable whenNotPaused {
        ExecuteBuyNowParams memory params;
        params.collection = _collection;
        params.tokenId = _tokenId;
        params.vault = _vault;
        params.marketplace = _marketplace;

        ReserveData memory reserveData = LibLiquidity.getReserveData(
            params.collection
        );

        BorrowState storage borrowState = LibLoan.getBorrowState(
            params.collection,
            reserveData.currency
        );

        // 0. check if the user owns the vault
        if (LibVault.getVaultAddress(_msgSender()) != params.vault) {
            revert Unauthorised();
        }

        // 1. get price for params.tokenId  and floor price pv
        params.totalPrincipal = MarketplaceAdapterFacet(address(this))
            .extractAssetPrice(_marketplace, _data);
        (params.fv, params.timestamp) = IPriceOracle(reserveData.priceOracle)
            .getTwap(params.collection);

        if (params.fv == 0) {
            revert InvalidFloorPrice();
        }

        if (params.fv < params.totalPrincipal) {
            revert InvalidPrincipal();
        }

        // 2. get borrow params and borrow rate
        ReserveConfigurationMap memory reserveConf = LibReserveConfiguration
            .getConfiguration(params.collection);
        (params.epoch, params.term) = reserveConf.getBorrowParams();
        params.nper = params.term / params.epoch;

        (
            params.liquidityRate,
            params.borrowRate
        ) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateInterestRates(
                reserveData.currency,
                reserveData.seniorDepositTokenAddress,
                0,
                params.outstandingPrincipal,
                borrowState.totalDebt,
                borrowState.avgBorrowRate
            );

        // 3. insert debt, get total interest and PMT
        (params.loanId, params.pmt, params.totalInterest) = LibLoan.insertDebt(
            params.collection,
            reserveData.currency,
            params.tokenId,
            params.vault,
            params.totalPrincipal,
            params.term,
            params.epoch,
            params.borrowRate
        );

        // 4. calculate downpayment and outstanding principal, interest and debt
        params.downpayment = params.pmt.pmt;
        params.outstandingPrincipal =
            params.totalPrincipal -
            params.pmt.principal;
        params.outstandingInterest = params.totalInterest - params.pmt.interest;
        params.outstandingDebt =
            params.outstandingPrincipal +
            params.outstandingInterest;

        // 5. check credit limit against with outstanding debt
        uint256 availableCreditLimit = LibVault.getCreditLimit(
            params.vault,
            params.collection,
            reserveData.currency,
            params.fv
        );
        if (availableCreditLimit < params.outstandingDebt) {
            revert InsufficientCreditLimit();
        }

        // 6. check if pool liquidity against with outstanding principal
        params.totalPending = IVToken(reserveData.seniorDepositTokenAddress)
            .totalUnbonding();
        params.totalBalance = IERC20(reserveData.currency).balanceOf(
            reserveData.seniorDepositTokenAddress
        );
        console.log("currency: ", reserveData.currency);
        console.log(
            "senior deposit tokenAddress: ",
            reserveData.seniorDepositTokenAddress
        );
        console.log("balance: ", params.totalBalance);
        if (params.totalBalance > params.totalPending) {
            params.availableLiquidity =
                params.totalBalance -
                params.totalPending;
        }

        if (params.availableLiquidity < params.outstandingPrincipal) {
            revert InsufficientLiquidity();
        }

        // 7.1 receive downpayment
        if (params.downpayment > msg.value) {
            IERC20(reserveData.currency).safeTransferFrom(
                msg.sender,
                address(this),
                (params.downpayment - msg.value)
            );
        } else {
            if (params.downpayment != msg.value) {
                revert InvalidValueTransfered();
            }
        }

        // 7.2 protocol fee
        uint256 protocolFee = params.totalPrincipal.percentMul(
            LibAppStorage.ds().protocolFee.cutRatio
        );
        IERC20(reserveData.currency).safeTransferFrom(
            msg.sender,
            LibAppStorage.ds().protocolFee.treasuryAddress,
            protocolFee
        );

        // 8.1 transfer money to this
        IVToken(reserveData.seniorDepositTokenAddress).transferUnderlyingTo(
            address(this),
            params.outstandingPrincipal
        );

        // 8.2 unwrap weth
        PaymentsFacet(address(this)).unwrapWETH9(
            params.outstandingPrincipal,
            address(this)
        );

        SafeTransferLib.safeTransferETH(params.vault, params.totalPrincipal);

        // 9. purchase nft
        (params.pmt.principal, params.pmt.interest) = LibLoan.getPMT(
            params.collection,
            reserveData.currency,
            params.vault,
            params.loanId
        );
        MarketplaceAdapterFacet(address(this)).purchase(
            params.marketplace,
            params.vault,
            _data
        );

        // 10. first payment
        LibLoan.repay(
            params.collection,
            reserveData.currency,
            params.vault,
            params.loanId
        );

        // 11. distribute interest
        LibLoan.distributeInterest(
            reserveData,
            params.pmt.interest,
            _msgSender()
        );

        emit Borrow(
            params.vault,
            params.collection,
            reserveData.currency,
            params.loanId,
            params.totalPrincipal,
            params.totalInterest,
            params.borrowRate
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
            _loan
        );

        // 3. distribute interest
        LibLoan.distributeInterest(reserveData, params.interest, _msgSender());

        IERC20(reserveData.currency).safeTransferFrom(
            _msgSender(),
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
        (param.liquidationBonus, param.gracePeriod) = reserveConf
            .getLiquidationParams();

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

        // 3 get floor price from oracle contract
        IPriceOracle priceOracle = IPriceOracle(reserveData.priceOracle);
        (param.floorPrice, param.floorPriceTime) = priceOracle.getTwap(
            param.collection
        );

        if (param.floorPrice == 0) {
            revert InvalidFloorPrice();
        }

        // 3 get pmt info
        (param.principal, param.interest) = LibLoan.getPMT(
            param.collection,
            param.currency,
            param.vault,
            param.loanId
        );
        param.totalDebt = param.principal;
        param.remaningDebt = param.totalDebt;
        param.discount = getDiscount(param.floorPrice, param.liquidationBonus);
        param.discountedFloorPrice = param.floorPrice - param.discount;

        // 4 transfer all nfts to liquidator
        uint256[] memory collaterals = LibLoan.releaseLien(
            param.collection,
            param.currency,
            param.vault,
            param.loanId
        );

        uint256 discountedFloorPriceInTotal = param.discountedFloorPrice *
            collaterals.length;
        IERC20(param.currency).safeTransferFrom(
            param.liquidator,
            address(this),
            discountedFloorPriceInTotal
        );
        param.receivedAmount += discountedFloorPriceInTotal;

        for (uint256 i = 0; i < collaterals.length; i++) {
            bytes4 selector = IERC721(param.collection).transferFrom.selector;
            bytes memory data = abi.encodePacked(
                selector,
                abi.encode(param.vault, param.liquidator, collaterals[i])
            );
            bytes memory encodedData = abi.encode(param.collection, data);
            IVault(_vault).exec(encodedData);
        }

        emit CollateralTransferred(
            param.collection,
            param.vault,
            param.liquidator,
            collaterals
        );

        if (param.totalDebt > discountedFloorPriceInTotal) {
            param.remaningDebt = param.totalDebt - discountedFloorPriceInTotal;
        } else {
            uint256 refundAmount = discountedFloorPriceInTotal -
                param.totalDebt;
            IERC20(param.currency).transfer(param.vault, refundAmount);
            param.receivedAmount -= refundAmount;
        }

        // 5. transfer from junior tranche if there is still remaning debt
        if (param.remaningDebt > 0) {
            param.totalAssetFromJuniorTranche = ERC4626(
                reserveData.juniorDepositTokenAddress
            ).totalAssets();

            if (param.totalAssetFromJuniorTranche >= param.remaningDebt) {
                IVToken(reserveData.juniorDepositTokenAddress)
                    .transferUnderlyingTo(address(this), param.remaningDebt);
                param.juniorTrancheAmount = param.remaningDebt;
                param.receivedAmount += param.remaningDebt;
            } else {
                IVToken(reserveData.juniorDepositTokenAddress)
                    .transferUnderlyingTo(
                        address(this),
                        param.totalAssetFromJuniorTranche
                    );
                param.juniorTrancheAmount = param.totalAssetFromJuniorTranche;
                param.receivedAmount += param.totalAssetFromJuniorTranche;
                param.writeDownAmount =
                    param.remaningDebt -
                    param.totalAssetFromJuniorTranche;
            }
        }

        // 6. record repay info
        (param.repaymentId, param.isFinal) = LibLoan.repay(
            param.collection,
            param.currency,
            param.vault,
            param.loanId
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

        // 7. transfer to senior deposit token
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
}

/* --------------------------------- errors -------------------------------- */
error Unauthorised();
error InsufficientLiquidity();
error InsufficientCreditLimit();
error InvalidDebt();
error InvalidLiquidate();
error InvalidFloorPrice();
error InvalidPrincipal();
error InvalidValueTransfered();

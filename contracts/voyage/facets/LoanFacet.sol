// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC4626} from "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibLoan, ExecuteBuyNowParams} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibMarketplace} from "../libraries/LibMarketplace.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {AssetInfo} from "../interfaces/IMarketPlaceAdapter.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IVaultFacet} from "../interfaces/IVaultFacet.sol";
import {ILoanFacet, ExecuteRepayParams, PreviewBuyNowParams} from "../interfaces/ILoanFacet.sol";
import {LibAppStorage, AppStorage, Storage, BorrowData, BorrowState, Loan, ReserveConfigurationMap, ReserveData, PMT} from "../libraries/LibAppStorage.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {LibPayments} from "../../shared/libraries/LibPayments.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {SafeTransferLib} from "../../shared/libraries/SafeTransferLib.sol";
import {IVault} from "../../vault/Vault.sol";
import {IUnbondingToken} from "../tokenization/SeniorDepositToken.sol";
import {IOracleFacet, Message} from "../interfaces/IOracleFacet.sol";
import {OracleFacet} from "../facets/OracleFacet.sol";

contract LoanFacet is ILoanFacet, Storage, ReentrancyGuard {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    uint256 public immutable TEN_THOUSANDS = 10000;

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

    function previewBuyNowParams(
        address _collection,
        address _vault,
        uint256 _principal
    ) external view returns (PreviewBuyNowParams memory) {
        PreviewBuyNowParams memory params;
        params.totalPrincipal = _principal;
        (
            ReserveData storage reserveData,
            BorrowData storage borrowData,
            BorrowState storage borrowState,
            ReserveConfigurationMap memory reserveConf
        ) = _getState(_collection, _vault);
        params.loanId = borrowData.nextLoanNumber;

        (params.epoch, params.term) = reserveConf.getBorrowParams();
        params.nper = params.term / params.epoch;

        uint256 outstandingPrincipal = params.totalPrincipal -
            params.totalPrincipal /
            params.nper;

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
    ) external payable whenNotPaused nonReentrant {
        ExecuteBuyNowParams memory params;
        _initializeParam(
            params,
            _collection,
            _tokenId,
            _vault,
            _marketplace,
            _data
        );

        // get shared data from storage
        (
            ReserveData storage reserveData,
            BorrowData storage borrowData,
            BorrowState storage borrowState,
            ReserveConfigurationMap memory reserveConf
        ) = _getState(params.collection, params.vault);

        params.currency = reserveData.currency;
        params.totalOutstandingDebt = borrowData.totalPrincipal;

        // validate parameters
        _validateBuyNowV1(params, reserveData, reserveConf);

        // initialize loan
        _initializeLoan(params, reserveData, borrowState, borrowData);

        // execute buyNow
        _executeBuyNow(params, reserveData, borrowState);

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

    function buyNowV2(
        address _collection,
        uint256 _tokenId,
        address payable _vault,
        address _marketplace,
        bytes calldata _data,
        Message calldata _message
    ) external payable whenNotPaused nonReentrant {
        ExecuteBuyNowParams memory params;
        _initializeParam(
            params,
            _collection,
            _tokenId,
            _vault,
            _marketplace,
            _data
        );

        (
            ReserveData storage reserveData,
            BorrowData storage borrowData,
            BorrowState storage borrowState,
            ReserveConfigurationMap memory reserveConf
        ) = _getState(params.collection, params.vault);

        params.currency = reserveData.currency;
        params.totalOutstandingDebt = borrowData.totalPrincipal;

        // validate parameters
        _validateBuyNowV2(params, reserveData, reserveConf, _message);

        // initialize loan
        _initializeLoan(params, reserveData, borrowState, borrowData);

        // execute buyNow
        _executeBuyNow(params, reserveData, borrowState);

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

    function getVaultDebt(address _collection, address _vault)
        external
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

    function _executeBuyNow(
        ExecuteBuyNowParams memory params,
        ReserveData memory reserveData,
        BorrowState storage borrowState
    ) internal {
        // transfer senior deposit to this
        IVToken(reserveData.seniorDepositTokenAddress).transferUnderlyingTo(
            address(this),
            params.outstandingPrincipal
        );

        {
            uint256 vaultWETHBalance = IERC20(reserveData.currency).balanceOf(
                params.vault
            );
            uint256 vaultETHBalance = params.vault.balance;
            // if currency is native eth
            if (params.assetInfo.currency == address(0)) {
                uint256 ethNeeded;
                uint256 wethNeeded;
                if (params.downpayment > vaultETHBalance) {
                    ethNeeded = params.downpayment - vaultETHBalance;
                }
                if (params.pmt.interest + params.pmt.fee > vaultWETHBalance) {
                    wethNeeded =
                        params.pmt.interest +
                        params.pmt.fee -
                        vaultWETHBalance;
                }
                LibPayments.wrapAndUnwrapETH(
                    params.vault,
                    ethNeeded,
                    wethNeeded
                );
                LibPayments.unwrapWETH9(
                    params.outstandingPrincipal,
                    address(this)
                );

                SafeTransferLib.safeTransferETH(
                    params.vault,
                    params.outstandingPrincipal
                );
                LibMarketplace.purchase(
                    params.marketplace,
                    params.vault,
                    params.totalPrincipal,
                    params.data
                );
            } else {
                // if currency is weth
                if (
                    vaultWETHBalance <
                    params.downpayment + params.pmt.interest + params.pmt.fee
                ) {
                    LibPayments.wrapAndUnwrapETH(
                        params.vault,
                        0,
                        params.downpayment +
                            params.pmt.interest +
                            params.pmt.fee -
                            vaultWETHBalance
                    );
                }

                IERC20(LibAppStorage.ds().WETH9).safeTransfer(
                    params.vault,
                    params.outstandingPrincipal
                );

                LibMarketplace.purchase(
                    params.marketplace,
                    params.vault,
                    0,
                    params.data
                );
            }
        }

        {
            // distrubute interest and protocol fee before unwrap weth to eth
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
        }
    }

    function _initializeLoan(
        ExecuteBuyNowParams memory params,
        ReserveData storage reserveData,
        BorrowState storage borrowState,
        BorrowData storage borrowData
    ) internal {
        (params.borrowRate) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateBorrowRate(
                reserveData.currency,
                reserveData.seniorDepositTokenAddress,
                0,
                params.outstandingPrincipal,
                borrowState.totalDebt
            );

        // insert debt, get total interest and PMT
        params.incomeRatio = LibReserveConfiguration
            .getConfiguration(params.collection)
            .getIncomeRatio();
        (params.takeRate, params.treasury) = LibLiquidity
            .getTakeRateAndTreasuryAddr();
        (params.loanId, params.pmt, params.totalInterest, params.fee) = LibLoan
            .initDebt(borrowState, borrowData, params);

        // calculate downpayment and outstanding interest and debt
        params.downpayment = params.pmt.principal;
        params.outstandingInterest = params.totalInterest - params.pmt.interest;

        // check the combined balance against downpayment and interest
        if (
            (params.vault.balance +
                IERC20(reserveData.currency).balanceOf(params.vault)) <
            params.downpayment + params.pmt.interest + params.pmt.fee
        ) {
            revert InsufficientVaultETHBalance();
        }

        // first payment
        LibLoan.firstRepay(
            borrowState,
            borrowData,
            params.loanId,
            params.incomeRatio
        );
    }

    function _validateBuyNowV1(
        ExecuteBuyNowParams memory params,
        ReserveData storage reserveData,
        ReserveConfigurationMap memory reserveConf
    ) internal {
        _validateBasic(params);

        (params.fv, params.timestamp) = IPriceOracle(
            reserveData.priceOracle.implementation()
        ).getTwap(params.collection);

        _validateTWAPAndFloorPrice(params, reserveData, reserveConf);

        _validateLiquidity(params, reserveData, reserveConf);
    }

    function _validateBuyNowV2(
        ExecuteBuyNowParams memory params,
        ReserveData storage reserveData,
        ReserveConfigurationMap memory reserveConf,
        Message calldata message
    ) internal {
        _validateBasic(params);

        (
            address messageCurrency,
            uint256 price
        ) = _verifyAndExtractPriceFromMessage(params, reserveConf, message);

        // check currency
        if (reserveData.currency != messageCurrency) {
            revert InvalidTwapCurrency();
        }

        params.fv = price;
        params.timestamp = message.timestamp;

        _validateTWAPAndFloorPrice(params, reserveData, reserveConf);

        _validateLiquidity(params, reserveData, reserveConf);
    }

    function _verifyAndExtractPriceFromMessage(
        ExecuteBuyNowParams memory params,
        ReserveConfigurationMap memory reserveConf,
        Message calldata message
    ) internal returns (address, uint256) {
        // construct the message id corresponding to the collection (using EIP-712 structured-data hashing)
        bytes32 messageId = IOracleFacet(address(this)).getMessageId(
            params.collection
        );
        // validate the price message
        if (
            !IOracleFacet(address(this)).verifyMessage(
                messageId,
                reserveConf.getMaxTwapStaleness(),
                message
            )
        ) {
            revert InvalidTwapMessage();
        }

        (address messageCurrency, uint256 price) = abi.decode(
            message.payload,
            (address, uint256)
        );

        return (messageCurrency, price);
    }

    function _validateBasic(ExecuteBuyNowParams memory params) internal {
        // check if the user owns the vault address
        if (LibVault.getVaultAddress(_msgSender()) != params.vault) {
            revert Unauthorised();
        }

        // check collection address and token id
        params.assetInfo = LibMarketplace.extractAssetInfo(
            params.marketplace,
            params.data
        );
        params.totalPrincipal = params.assetInfo.assetPrice;

        if (params.collection != params.assetInfo.collection) {
            revert InvalidCollection();
        }

        if (params.tokenId != params.assetInfo.tokenId) {
            revert InvalidTokenid();
        }

        if (
            params.assetInfo.currency != address(0) &&
            params.assetInfo.currency != address(LibAppStorage.ds().WETH9)
        ) {
            revert InvalidCurrencyType();
        }
    }

    function _validateTWAPAndFloorPrice(
        ExecuteBuyNowParams memory params,
        ReserveData storage reserveData,
        ReserveConfigurationMap memory reserveConf
    ) internal {
        if (
            (block.timestamp - params.timestamp) >
            reserveConf.getMaxTwapStaleness()
        ) {
            revert BuyNowStaleTwap();
        }

        // check floor
        if (params.fv == 0) {
            revert InvalidFloorPrice();
        }

        if (params.fv < params.totalPrincipal) {
            revert ExceedsFloorPrice();
        }
    }

    function _validateLiquidity(
        ExecuteBuyNowParams memory params,
        ReserveData storage reserveData,
        ReserveConfigurationMap memory reserveConf
    ) internal {
        // check junior tranche balance
        params.totalSeniorBalance = IERC20(reserveData.currency).balanceOf(
            reserveData.seniorDepositTokenAddress
        );

        // get borrow params and borrow rate
        (params.epoch, params.term) = reserveConf.getBorrowParams();

        params.nper = params.term / params.epoch;

        params.outstandingPrincipal =
            params.totalPrincipal -
            params.totalPrincipal /
            params.nper;

        // check junior tranche balance and available liquidity
        params.totalJuniorBalance = IERC20(reserveData.currency).balanceOf(
            reserveData.juniorDepositTokenAddress
        );

        if (params.totalJuniorBalance == 0) {
            revert InvalidJuniorTrancheBalance();
        }

        params.totalSeniorBalance = IERC20(reserveData.currency).balanceOf(
            reserveData.seniorDepositTokenAddress
        );

        if (
            params.outstandingPrincipal.percentDiv(
                reserveConf.getOptimalLiquidityRatio()
            ) > params.totalJuniorBalance
        ) {
            revert InsufficientJuniorLiquidity();
        }

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
    }

    function _getState(address _collection, address _vault)
        internal
        view
        returns (
            ReserveData storage,
            BorrowData storage,
            BorrowState storage,
            ReserveConfigurationMap memory
        )
    {
        ReserveData storage reserveData = LibLiquidity.getReserveData(
            _collection
        );
        BorrowData storage borrowData = LibLoan.getBorrowData(
            _collection,
            reserveData.currency,
            _vault
        );
        BorrowState storage borrowState = LibLoan.getBorrowState(
            _collection,
            reserveData.currency
        );

        ReserveConfigurationMap memory reserveConf = LibReserveConfiguration
            .getConfiguration(_collection);

        return (reserveData, borrowData, borrowState, reserveConf);
    }

    function _initializeParam(
        ExecuteBuyNowParams memory params,
        address _collection,
        uint256 _tokenId,
        address payable _vault,
        address _marketplace,
        bytes calldata _data
    ) internal {
        params.collection = _collection;
        params.tokenId = _tokenId;
        params.vault = _vault;
        params.marketplace = _marketplace;
        params.data = _data;
    }
}

/* --------------------------------- errors -------------------------------- */
error Unauthorised();
error InsufficientCash();
error InsufficientLiquidity();
error InsufficientJuniorLiquidity();
error InsufficientVaultWETHBalance();
error InsufficientVaultETHBalance();
error InvalidLiquidate();
error InvalidFloorPrice();
error InvalidCollection();
error InvalidTokenid();
error InvalidPrincipal();
error InvalidJuniorTrancheBalance();
error InvalidCurrencyType();
error ExceedsFloorPrice();
error BuyNowStaleTwap();
error LiquidateStaleTwap();
error InvalidTwapMessage();
error InvalidTwapCurrency();

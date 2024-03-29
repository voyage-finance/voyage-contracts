// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {ILiquidityFacet} from "../interfaces/ILiquidityFacet.sol";
import {JuniorDepositToken} from "../tokenization/JuniorDepositToken.sol";
import {SeniorDepositToken} from "../tokenization/SeniorDepositToken.sol";
import {LibAppStorage, AppStorage, Storage, Tranche, ReserveData, BorrowState, ReserveConfigurationMap} from "../libraries/LibAppStorage.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {IERC4626} from "../../shared/interfaces/IERC4626.sol";
import {IWETH9, LibPayments} from "../../shared/libraries/LibPayments.sol";
import {IUnbondingToken} from "../tokenization/SeniorDepositToken.sol";

contract LiquidityFacet is Storage, ReentrancyGuard, ILiquidityFacet {
    using LibLiquidity for ReserveData;
    using LibReserveConfiguration for ReserveConfigurationMap;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    /* ----------------------------- admin interface ---------------------------- */
    function initReserve(
        address _collection,
        address _currency,
        address _interestRateStrategyAddress,
        address _priceOracle
    ) external authorised {
        if (_currency != address(LibAppStorage.ds().WETH9)) {
            revert InvalidContract();
        }
        ReserveData storage reserveData = LibLiquidity.getReserveData(
            _collection
        );
        if (reserveData.initialized) {
            revert InvalidInitialize();
        }
        reserveData.init(
            _collection,
            _currency,
            _interestRateStrategyAddress,
            _priceOracle
        );
        LibAppStorage.ds()._reserveList[
            LibAppStorage.ds()._reservesCount
        ] = _collection;
        LibAppStorage.ds()._reservesCount++;
        emit ReserveInitialized(
            _collection,
            _currency,
            reserveData.juniorDepositTokenAddress,
            reserveData.seniorDepositTokenAddress,
            _interestRateStrategyAddress
        );
    }

    function activateReserve(address _collection) external authorised {
        modifyReserveStatus(_collection, true);
        emit ReserveActivated(_collection);
    }

    function deactivateReserve(address _collection) external authorised {
        modifyReserveStatus(_collection, false);
        emit ReserveInactived(_collection);
    }

    function modifyReserveStatus(address _collection, bool active) internal {
        if (!Address.isContract(_collection)) {
            revert InvalidContract();
        }
        ReserveConfigurationMap memory config = LibReserveConfiguration
            .getConfiguration(_collection);
        config.setActive(active);
        LibReserveConfiguration.saveConfiguration(_collection, config);
    }

    function updateProtocolFee(address _treasuryAddr, uint40 _takeRate)
        external
        authorised
    {
        LibLiquidity.updateProtocolFee(_treasuryAddr, _takeRate);
        emit ProtocolFeeUpdated(_treasuryAddr, _takeRate);
    }

    function upgradePriceOracleImpl(address _collection, address _priceOracle)
        external
        authorised
    {
        ReserveData storage reserveData = LibLiquidity.getReserveData(
            _collection
        );
        reserveData.priceOracle.upgradeTo(_priceOracle);
    }

    function updateWETH9(address _weth9) external authorised {
        LibLiquidity.updateWETH9(_weth9);
    }

    /* ----------------------------- user interface ----------------------------- */

    function deposit(
        address _collection,
        Tranche _tranche,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        ReserveData memory reserve = LibAppStorage.ds()._reserveData[
            _collection
        ];

        IVToken vToken = _tranche == Tranche.JUNIOR
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        // transfer the underlying tokens to liquidity manager, then do deposit.
        LibPayments.pullToken(
            vToken.asset(),
            _amount,
            msg.sender,
            address(this)
        );
        vToken.deposit(_amount, msg.sender);
        emit Deposit(
            _collection,
            reserve.currency,
            msg.sender,
            _tranche,
            _amount
        );
    }

    function withdraw(
        address _collection,
        Tranche _tranche,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        ReserveData memory reserve = LibAppStorage.ds()._reserveData[
            _collection
        ];
        IVToken vToken = Tranche.JUNIOR == _tranche
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        uint256 userBalance = vToken.maxWithdraw(_msgSender());
        uint256 amountToWithdraw = _amount;
        if (_amount == type(uint256).max || _amount > userBalance) {
            amountToWithdraw = userBalance;
        }
        require(amountToWithdraw <= userBalance, "InvalidWithdrawal");
        BorrowState storage borrowState = LibAppStorage.ds()._borrowState[
            _collection
        ][reserve.currency];
        IERC4626(vToken).withdraw(amountToWithdraw, _msgSender(), _msgSender());

        emit Withdraw(
            _collection,
            reserve.currency,
            _msgSender(),
            _tranche,
            amountToWithdraw
        );
    }

    /* ---------------------------------- views --------------------------------- */

    function getReserveStatus(address _collection)
        external
        view
        returns (bool initialized, bool activated)
    {
        initialized = LibLiquidity.getReserveData(_collection).initialized;
        (activated, , ) = LibReserveConfiguration
            .getConfiguration(_collection)
            .getFlags();
    }

    function balance(
        address _collection,
        address _user,
        Tranche _tranche
    ) external view returns (uint256) {
        return LibLiquidity.balance(_collection, _user, _tranche);
    }

    function unbonding(address _collection, address _user)
        external
        view
        returns (uint256)
    {
        return LibLiquidity.unbonding(_collection, _user);
    }

    function getReserveFlags(address _currency)
        external
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return LibReserveConfiguration.getConfiguration(_currency).getFlags();
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidInitialize();
error InvalidContract();
error InvalidWithdrawal();

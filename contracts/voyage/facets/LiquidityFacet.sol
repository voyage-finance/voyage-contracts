// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {JuniorDepositToken} from "../tokenization/JuniorDepositToken.sol";
import {SeniorDepositToken} from "../tokenization/SeniorDepositToken.sol";
import {LibAppStorage, AppStorage, Storage, Tranche, ReserveData, BorrowState, ReserveConfigurationMap} from "../libraries/LibAppStorage.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PaymentsFacet} from "../../shared/facets/PaymentsFacet.sol";

contract LiquidityFacet is Storage {
    using LibLiquidity for ReserveData;
    using LibReserveConfiguration for ReserveConfigurationMap;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    event ReserveInitialized(
        address indexed _collection,
        address indexed _currency,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress
    );
    event ReserveActivated(address indexed _collection);
    event Deposit(
        address indexed _collection,
        address indexed _currency,
        address indexed _user,
        Tranche _tranche,
        uint256 amount
    );
    event Withdraw(
        address indexed _collection,
        address indexed _currency,
        address indexed _user,
        Tranche _tranche,
        uint256 amount
    );

    /* ----------------------------- admin interface ---------------------------- */
    function initReserve(
        address _collection,
        address _currency,
        address _interestRateStrategyAddress,
        address _priceOracle
    ) external authorised {
        if (
            !Address.isContract(_collection) || !Address.isContract(_currency)
        ) {
            revert InvalidContract();
        }
        ReserveData storage reserveData = LibLiquidity.getReserveData(
            _collection
        );
        if (reserveData.initialized) {
            revert InvalidInitialize();
        }
        reserveData.init(_currency, _interestRateStrategyAddress, _priceOracle);
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
        if (!Address.isContract(_collection)) {
            revert InvalidContract();
        }
        ReserveConfigurationMap memory config = LibReserveConfiguration
            .getConfiguration(_collection);
        config.setActive(true);
        LibReserveConfiguration.saveConfiguration(_collection, config);
        emit ReserveActivated(_collection);
    }

    function updateProtocolFee(address _treasuryAddr, uint256 _cutRatio)
        external
        authorised
    {
        LibLiquidity.updateProtocolFee(_treasuryAddr, _cutRatio);
    }

    function updateWETH9(address _weth9) external authorised {
        LibLiquidity.updateWETH9(_weth9);
    }

    /* ----------------------------- user interface ----------------------------- */

    function deposit(
        address _collection,
        Tranche _tranche,
        uint256 _amount
    ) external {
        ReserveData memory reserve = LibAppStorage.ds()._reserveData[
            _collection
        ];
        BorrowState memory borrowState = LibAppStorage.ds()._borrowState[
            _collection
        ][reserve.currency];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;
        uint256 avgBorrowRate = borrowState.avgBorrowRate;

        IVToken vToken = _tranche == Tranche.JUNIOR
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        // transfer the underlying tokens to liquidity manager, then do deposit.
        PaymentsFacet(address(this)).pullToken(
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
    ) external {
        ReserveData memory reserve = LibAppStorage.ds()._reserveData[
            _collection
        ];
        IVToken vToken = Tranche.JUNIOR == _tranche
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        uint256 userBalance = vToken.maxWithdraw(msg.sender);
        uint256 amountToWithdraw = _amount;
        if (_amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        BorrowState memory borrowState = LibAppStorage.ds()._borrowState[
            _collection
        ][reserve.currency];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;
        uint256 avgBorrowRate = borrowState.avgBorrowRate;
        IVToken(vToken).withdraw(_amount, msg.sender, msg.sender);

        emit Withdraw(
            _collection,
            reserve.currency,
            msg.sender,
            _tranche,
            _amount
        );
    }

    /* ---------------------------------- views --------------------------------- */

    function getReserveStatus(address _collection)
        public
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
    ) public view returns (uint256) {
        return LibLiquidity.balance(_collection, _user, _tranche);
    }

    function unbonding(
        address _collection,
        address _user,
        Tranche _tranche
    ) public view returns (uint256) {
        return LibLiquidity.unbonding(_collection, _user, _tranche);
    }

    function utilizationRate(address _collection, address _currency)
        external
        view
        returns (uint256)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_currency);
        BorrowState storage borrowState = LibAppStorage.ds()._borrowState[
            _collection
        ][_currency];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;

        uint256 totalPendingWithdrawal = IVToken(
            reserve.seniorDepositTokenAddress
        ).totalUnbonding();

        uint256 availableLiquidity = IERC20(_currency).balanceOf(
            reserve.seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        return
            totalDebt == 0
                ? 0
                : totalDebt.rayDiv(availableLiquidity + totalDebt);
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

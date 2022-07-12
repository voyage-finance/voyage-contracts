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
import {PeripheryPayments} from "../../shared/util/PeripheryPayments.sol";

contract LiquidityFacet is Storage, PeripheryPayments {
    using LibLiquidity for ReserveData;
    using LibReserveConfiguration for ReserveConfigurationMap;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    event ReserveInitialized(
        address indexed _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress,
        uint256 _optimalIncomeRatio
    );
    event ReserveActivated(address indexed _asset);
    event Deposit(
        address indexed asset,
        address indexed user,
        Tranche indexed tranche,
        uint256 amount
    );
    event Withdraw(
        address indexed asset,
        address indexed user,
        Tranche indexed tranche,
        uint256 amount
    );

    /* ----------------------------- admin interface ---------------------------- */

    function initReserve(
        address _asset,
        address _interestRateStrategyAddress,
        address _loanStrategyAddress,
        uint256 _optimalIncomeRatio,
        address _priceOracle,
        address _nftAddr
    ) external authorised {
        if (!Address.isContract(_asset)) {
            revert InvalidContract();
        }
        ReserveData storage reserveData = LibLiquidity.getReserveData(_asset);
        if (reserveData.initialized) {
            revert InvalidInitialize();
        }
        reserveData.init(
            _asset,
            _interestRateStrategyAddress,
            _loanStrategyAddress,
            _optimalIncomeRatio,
            _priceOracle,
            _nftAddr
        );
        s._reserveList[s._reservesCount] = _asset;
        s._reservesCount++;
        emit ReserveInitialized(
            _asset,
            reserveData.juniorDepositTokenAddress,
            reserveData.seniorDepositTokenAddress,
            _interestRateStrategyAddress,
            _optimalIncomeRatio
        );
    }

    function activateReserve(address _asset) external authorised {
        if (!Address.isContract(_asset)) {
            revert InvalidContract();
        }
        ReserveConfigurationMap memory config = LibLiquidity.getConfiguration(
            _asset
        );
        config.setActive(true);
        s._reserves[_asset].configuration.data = config.data;
        emit ReserveActivated(_asset);
    }

    /* ----------------------------- user interface ----------------------------- */

    function deposit(
        address _asset,
        Tranche _tranche,
        uint256 _amount,
        address _user
    ) external {
        ReserveData memory reserve = s._reserves[_asset];
        BorrowState memory borrowState = s._borrowState[_asset];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;
        uint256 avgBorrowRate = borrowState.avgBorrowRate;
        LibLiquidity.updateStateOnDeposit(
            _asset,
            _tranche,
            _amount,
            totalDebt,
            avgBorrowRate
        );

        IVToken vToken = _tranche == Tranche.JUNIOR
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        // transfer the underlying tokens to liquidity manager, then do deposit.
        pullToken(vToken.asset(), _amount, _user, address(this));
        vToken.deposit(_amount, _user);
        emit Deposit(_asset, _user, _tranche, _amount);
    }

    function withdraw(
        address _asset,
        Tranche _tranche,
        uint256 _amount,
        address payable _user
    ) external {
        ReserveData memory reserve = s._reserves[_asset];
        IVToken vToken = Tranche.JUNIOR == _tranche
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        uint256 userBalance = vToken.maxWithdraw(_user);
        uint256 amountToWithdraw = _amount;
        if (_amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        BorrowState memory borrowState = s._borrowState[_asset];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;
        uint256 avgBorrowRate = borrowState.avgBorrowRate;
        IVToken(vToken).withdraw(_amount, _user, _user);
        LibLiquidity.updateStateOnWithdraw(
            _asset,
            _tranche,
            amountToWithdraw,
            totalDebt,
            avgBorrowRate
        );

        emit Withdraw(_asset, _user, _tranche, _amount);
    }

    /* ---------------------------------- views --------------------------------- */

    function getReserveStatus(address _reserve)
        public
        view
        returns (bool initialized, bool activated)
    {
        initialized = LibLiquidity.getReserveData(_reserve).initialized;
        (activated, , ) = LibLiquidity.getFlags(_reserve);
    }

    function balance(
        address _reserve,
        address _user,
        Tranche _tranche
    ) public view returns (uint256) {
        return LibLiquidity.balance(_reserve, _user, _tranche);
    }

    function liquidityRate(address _asset, Tranche _tranche)
        public
        view
        returns (uint256)
    {
        return LibLiquidity.getLiquidityRate(_asset, _tranche);
    }

    function unbonding(
        address _reserve,
        address _user,
        Tranche _tranche
    ) public view returns (uint256) {
        return LibLiquidity.unbonding(_reserve, _user, _tranche);
    }

    function utilizationRate(address _reserve) external view returns (uint256) {
        ReserveData memory reserve = LibLiquidity.getReserveData(_reserve);
        BorrowState storage borrowState = s._borrowState[_reserve];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;

        uint256 totalPendingWithdrawal = IVToken(
            reserve.seniorDepositTokenAddress
        ).totalUnbonding();

        uint256 availableLiquidity = IERC20(_reserve).balanceOf(
            reserve.seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        return
            totalDebt == 0
                ? 0
                : totalDebt.rayDiv(availableLiquidity + totalDebt);
    }

    function getReserveFlags(address _reserve)
        external
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return LibLiquidity.getFlags(_reserve);
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidInitialize();
error InvalidContract();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './ReserveManager.sol';
import '../../libraries/helpers/Errors.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../../libraries/math/WadRayMath.sol';
import {IERC20} from 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/ILiquidityManager.sol';
import {IVToken} from '../../interfaces/IVToken.sol';
import {JuniorDepositToken} from '../../tokenization/JuniorDepositToken.sol';
import {SeniorDepositToken} from '../../tokenization/SeniorDepositToken.sol';
import {PeripheryPayments} from '../../libraries/utils/PeripheryPayments.sol';

contract LiquidityManager is
    PeripheryPayments,
    ReserveManager,
    ILiquidityManager
{
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(address payable _proxy, address _voyager)
        ReserveManager(_proxy, _voyager)
    {}

    /************************************** User Functions **************************************/

    function deposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address _user
    ) external onlyProxy {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        DataTypes.ReserveData memory reserve = getReserveData(_asset);
        DataTypes.BorrowStat memory borrowStat = lms.getBorrowStat(_asset);
        uint256 totalDebt = borrowStat.totalDebt.add(borrowStat.totalInterest);
        uint256 avgBorrowRate = borrowStat.avgBorrowRate;

        lms.updateStateOnDeposit(
            _asset,
            _tranche,
            _amount,
            totalDebt,
            avgBorrowRate
        );

        IVToken vToken = _tranche == ReserveLogic.Tranche.JUNIOR
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        // transfer the underlying tokens to liquidity manager, then do deposit.
        pullToken(vToken.asset(), _amount, _user, address(this));
        vToken.deposit(_amount, _user);
        emitDeposit(_asset, _user, _tranche, _amount);
    }

    function withdraw(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address payable _user
    ) external onlyProxy {
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        DataTypes.ReserveData memory reserve = getReserveData(_asset);
        IVToken vToken = ReserveLogic.Tranche.JUNIOR == _tranche
            ? IVToken(reserve.juniorDepositTokenAddress)
            : IVToken(reserve.seniorDepositTokenAddress);
        uint256 userBalance = vToken.maxWithdraw(_user);
        uint256 amountToWithdraw = _amount;
        if (_amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        DataTypes.BorrowStat memory borrowStat = lms.getBorrowStat(_asset);
        uint256 totalDebt = borrowStat.totalDebt.add(borrowStat.totalInterest);
        uint256 avgBorrowRate = borrowStat.avgBorrowRate;
        IVToken(vToken).withdraw(_amount, _user, _user);
        lms.updateStateOnWithdraw(
            _asset,
            _tranche,
            amountToWithdraw,
            totalDebt,
            avgBorrowRate
        );

        emitWithdraw(_asset, _user, _tranche, _amount);
    }

    /************************************** View Functions **************************************/

    function unbonding(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        DataTypes.ReserveData memory reserve = getReserveData(_reserve);
        address vToken;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
        } else {
            vToken = reserve.seniorDepositTokenAddress;
        }
        (, uint256[] memory amounts) = IVToken(vToken).unbonding(_user);
        uint256 unbondingBalance = 0;
        for (uint8 i = 0; i < amounts.length; i++) {
            unbondingBalance += amounts[i];
        }
        return unbondingBalance;
    }

    function balance(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        DataTypes.ReserveData memory reserve = getReserveData(_reserve);
        address vToken;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
        } else {
            vToken = reserve.seniorDepositTokenAddress;
        }
        return IVToken(vToken).maxWithdraw(_user);
    }

    function utilizationRate(address _reserve) external view returns (uint256) {
        DataTypes.ReserveData memory reserve = getReserveData(_reserve);

        uint256 totalPrincipal;
        uint256 totalInterest;
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        (totalPrincipal, totalInterest) = lms.getTotalDebt(_reserve);
        uint256 totalDebt = totalPrincipal.add(totalInterest);

        uint256 totalPendingWithdrawal = IVToken(
            reserve.seniorDepositTokenAddress
        ).totalUnbonding();

        uint256 availableLiquidity = IERC20(_reserve).balanceOf(
            reserve.seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        uint256 utilizationRate = totalDebt == 0
            ? 0
            : totalDebt.rayDiv(availableLiquidity.add(totalDebt));

        return utilizationRate;
    }

    /******************************************** Events *******************************************/

    function trancheToBytes32(ReserveLogic.Tranche tranche)
        public
        view
        returns (bytes32)
    {
        return ReserveLogic.trancheToBytes32(tranche);
    }

    event Deposit(
        address indexed asset,
        address indexed user,
        uint8 indexed tranche,
        uint256 amount
    );

    bytes32 internal constant DEPOSIT_SIG =
        keccak256('Deposit(address,address,uint8,uint256)');

    bytes32 internal constant WITHDRAW_SIG =
        keccak256('Withdraw(address,address,uint8,uint256)');

    function emitDeposit(
        address asset,
        address user,
        ReserveLogic.Tranche tranche,
        uint256 amount
    ) internal {
        proxy._emit(
            abi.encode(amount),
            4,
            DEPOSIT_SIG,
            addressToBytes32(asset),
            addressToBytes32(user),
            trancheToBytes32(tranche)
        );
    }

    function emitWithdraw(
        address asset,
        address user,
        ReserveLogic.Tranche tranche,
        uint256 amount
    ) internal {
        proxy._emit(
            abi.encode(amount),
            4,
            WITHDRAW_SIG,
            addressToBytes32(asset),
            addressToBytes32(user),
            trancheToBytes32(tranche)
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './ReserveManager.sol';
import '../../libraries/helpers/Errors.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../../libraries/math/WadRayMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../tokenization/InitializableDepositToken.sol';
import '../../tokenization/JuniorDepositToken.sol';
import '../../tokenization/SeniorDepositToken.sol';

contract LiquidityManager is ReserveManager, ILiquidityManager {
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

        address vToken;
        uint256 liquidityIndex;

        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
            liquidityIndex = getJuniorLiquidityIndex(_asset);
        } else {
            vToken = reserve.seniorDepositTokenAddress;
            liquidityIndex = getSeniorLiquidityIndex(_asset);
        }
        IVToken(vToken).mint(_user, _amount, liquidityIndex);
        IERC20(_asset).safeTransferFrom(_user, vToken, _amount);
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

        address vToken;
        uint256 liquidityIndex;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
            liquidityIndex = getJuniorLiquidityIndex(_asset);
        } else {
            vToken = reserve.seniorDepositTokenAddress;
            liquidityIndex = getSeniorLiquidityIndex(_asset);
        }

        uint256 userBalance = IERC20(vToken).balanceOf(_user);

        uint256 amountToWithdraw = _amount;

        if (_amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        DataTypes.BorrowStat memory borrowStat = lms.getBorrowStat(_asset);
        uint256 totalDebt = borrowStat.totalDebt.add(borrowStat.totalInterest);
        uint256 avgBorrowRate = borrowStat.avgBorrowRate;
        IVToken(vToken).burn(_user, amountToWithdraw, liquidityIndex);
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

    // todo @ian @xiaohuo this case, total balance should be the same as withdrawable amount
    function withdrawAbleAmount(
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
        return IERC20(vToken).balanceOf(_user);
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
        return IERC20(vToken).balanceOf(_user);
    }

    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getReserveNormalizedIncome(_asset, _tranche);
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

        uint256 totalPendingWithdrawal = InitializableDepositToken(
            reserve.seniorDepositTokenAddress
        ).totalPendingWithdrawal();

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

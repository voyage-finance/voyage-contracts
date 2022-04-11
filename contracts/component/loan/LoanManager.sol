// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxyable.sol';
import '../../interfaces/IVoyagerComponent.sol';
import '../../libraries/helpers/Errors.sol';
import '../Voyager.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../../interfaces/IMessageBus.sol';
import '../../interfaces/IHealthStrategy.sol';

contract LoanManager is Proxyable, IVoyagerComponent {
    using SafeMath for uint256;

    LiquidityDepositEscrow public liquidityDepositEscrow;
    IMessageBus public messageBus;

    constructor(
        address payable _proxy,
        address _voyager,
        address _escrow
    ) Proxyable(_proxy) {
        voyager = Voyager(_voyager);
        liquidityDepositEscrow = LiquidityDepositEscrow(_escrow);
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        uint256 amount;
    }

    function borrow(
        address _user,
        address _asset,
        uint256 _amount,
        address _vault
    ) external requireNotPaused {
        // 0. check if the user owns the vault
        address vault = messageBus.getVault(_user);
        require(vault == _vault, Errors.LOM_NOT_VAULT_OWNER);

        // 1. check if pool liquidity is sufficient
        uint256 juniorDepositAmount;
        uint256 seniorDepositAmount;
        uint256 totalDebt;
        (
            juniorDepositAmount,
            seniorDepositAmount,
            totalDebt
        ) = getDepositAndDebt();
        uint256 reserveBalance = seniorDepositAmount - totalDebt;
        require(reserveBalance >= _amount, Errors.LOM_RESERVE_NOT_SUFFICIENT);

        // 2. check HF
        DataTypes.ReserveData memory reserveData = messageBus.getReserveData(
            _asset
        );
        IHealthStrategy healthStrategy = IHealthStrategy(
            reserveData.healthStrategyAddress
        );
        //        uint256 securityDeposit = messageBus.getSecurityDeposit(_user, _asset);
        //        uint256 currentBorrowRate = reserveData.currentBorrowRate;
        //        uint256 lastUpdateTime = messageBus.getVaultLastUpdateTime(_vault);
        //healthStrategy.calculateHealthRisk(messageBus.getSecurityDeposit(_user, _asset), reserveData.currentBorrowRate);

        // 3. check credit limit
        uint256 availableCreditLimit = voyager.getAvailableCredit(
            _user,
            _asset
        );
        require(
            availableCreditLimit >= _amount,
            Errors.LOM_CREDIT_NOT_SUFFICIENT
        );

        // 4. update liquidity index and interest rate
        LiquidityManagerStorage lms = LiquidityManagerStorage(
            liquidityManagerStorageAddress()
        );
        lms.updateStateOnBorrow(_asset, _amount);
    }

    function _executeBorrow(ExecuteBorrowParams memory vars) internal {}

    function escrow() internal view override returns (LiquidityDepositEscrow) {
        return liquidityDepositEscrow;
    }
}

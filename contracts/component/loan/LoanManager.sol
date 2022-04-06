// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxyable.sol';
import '../../interfaces/IVoyagerComponent.sol';
import '../../libraries/helpers/Errors.sol';
import '../Voyager.sol';

contract LoanManager is Proxyable, IVoyagerComponent {
    LiquidityDepositEscrow public liquidityDepositEscrow;

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
        address vault
    ) external requireNotPaused {
        // 1. check if pool liquidity is sufficient
        uint256 reserveBalance = liquidityDepositEscrow.balanceOf(_asset);
        require(reserveBalance >= _amount, Errors.LOM_RESERVE_NOT_SUFFICIENT);

        // 2. check HF

        // 3. check credit limit
        uint256 availableCreditLimit = voyager.getAvailableCredit(
            _user,
            _asset
        );
        require(
            availableCreditLimit >= _amount,
            Errors.LOM_CREDIT_NOT_SUFFICIENT
        );
    }

    function _executeBorrow(ExecuteBorrowParams memory vars) internal {}

    function escrow() internal view override returns (LiquidityDepositEscrow) {
        return liquidityDepositEscrow;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../types/DataTypes.sol';

library EscrowLogic {
    function recordDeposit(
        DataTypes.Deposit[] storage _deposits,
        DataTypes.Deposit memory _deposit
    ) external {
        _deposits.push(_deposit);
    }

    function recordWithdrawal(
        DataTypes.Deposit[] storage _deposits,
        DataTypes.Withdrawal[] memory _withdrawals
    ) external {
        for (uint256 i = 0; i < _withdrawals.length; i++) {
            DataTypes.Withdrawal memory _withdrawal = _withdrawals[i];
            DataTypes.Deposit storage _deposit = _deposits[_withdrawal.index];
            if (_deposit.amount == _withdrawal.amount) {
                // TODO if _withdrawal.index == _deposits.length - 1
                _deposits[_withdrawal.index] = _deposits[_deposits.length - 1];
                _deposits.pop();
            } else {
                _deposits[_withdrawal.index].amount =
                    _deposits[_withdrawal.index].amount -
                    _withdrawal.amount;
            }
        }
    }
}

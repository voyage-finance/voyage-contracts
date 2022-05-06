pragma solidity ^0.8.0;

import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../../libraries/logic/ReserveLogic.sol';
import '../../../libraries/EthAddressLib.sol';
import '../../../libraries/types/DataTypes.sol';

contract EscrowStorage {
    using Address for address payable;
    using SafeERC20 for ERC20;

    event Deposited(address indexed payee, address token, uint256 scaledAmount);

    event Withdrawn(address indexed payee, address token, uint256 amount);

    // reserve address => amount
    mapping(address => uint256) private _deposits;

    // reserve address => user address => junior deposit record
    mapping(address => mapping(address => DataTypes.Deposit[]))
        private _juniorDepositRecords;

    // reserve address => user address => senior deposit record
    mapping(address => mapping(address => DataTypes.Deposit[]))
        private _seniorDepositRecords;

    uint40 private _lockupTimeInSeconds = 7 days;

    //    function recordDeposit(
    //        address _reserve,
    //        ReserveLogic.Tranche _tranche,
    //        address _user,
    //        uint256 _scaledAmount,
    //        uint40 timestamp
    //    ) internal {
    //        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
    //            _juniorDepositRecords[_reserve][_user].push(deposit);
    //        } else {
    //            _seniorDepositRecords[_reserve][_user].push(deposit);
    //        }
    //
    //        emit Deposited(_user, _reserve, _scaledAmount);
    //    }
    //
    //    function recordWithdrawal(
    //        address _reserve,
    //        ReserveLogic.Tranche _tranche,
    //        address payable _user,
    //        DataTypes.Withdrawal[] memory _withdrawals
    //    ) internal {
    //        DataTypes.Deposit[] storage _deposits;
    //        if (_tranche == ReserveLogic.Tranche.SENIOR) {
    //            _deposits = _seniorDepositRecords[_reserve][_user];
    //        } else {
    //            _deposits = _seniorDepositRecords[_reserve][_user];
    //        }
    //
    //        for (uint256 i = 0; i < _withdrawals.length; i++) {
    //            DataTypes.Withdrawal memory _withdrawal = _withdrawals[i];
    //            DataTypes.Deposit storage _deposit = _deposit[_withdrawal.index];
    //            if (_deposit.amount == _withdrawal.amount) {
    //                // TODO if _withdrawal.index == _deposits.length - 1
    //                _deposits[_withdrawal.index] = _deposits[_deposits.length - 1];
    //                _deposits.pop();
    //            } else {
    //                _deposits[_withdrawal.index].amount =
    //                    _deposits[_withdrawal.index].amount -
    //                    _withdrawal.amount;
    //            }
    //        }
    //    }
}

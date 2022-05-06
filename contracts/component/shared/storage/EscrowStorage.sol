pragma solidity ^0.8.0;

import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../../libraries/logic/ReserveLogic.sol';
import '../../../libraries/logic/EscrowLogic.sol';
import '../../../libraries/EthAddressLib.sol';
import '../../../libraries/types/DataTypes.sol';
import '../../../libraries/state/State.sol';

abstract contract EscrowStorage is State {
    using Address for address payable;
    using SafeERC20 for ERC20;
    using EscrowLogic for DataTypes.Deposit[];

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

    function _recordDeposit(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address _user,
        uint256 _scaledAmount,
        uint40 _timestamp
    ) internal {
        DataTypes.Deposit[] storage deposits;
        DataTypes.Deposit memory deposit;
        deposit.amount = _scaledAmount;
        deposit.depositTime = _timestamp;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            deposits = _juniorDepositRecords[_reserve][_user];
        } else {
            deposits = _seniorDepositRecords[_reserve][_user];
        }
        deposits.recordDeposit(deposit);
    }

    function _recordWithdrawal(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address payable _user,
        DataTypes.Withdrawal[] memory _withdrawals
    ) internal {
        DataTypes.Deposit[] storage _deposits;
        if (_tranche == ReserveLogic.Tranche.SENIOR) {
            _deposits = _seniorDepositRecords[_reserve][_user];
        } else {
            _deposits = _seniorDepositRecords[_reserve][_user];
        }
        _deposits.recordWithdrawal(_withdrawals);
    }
}

pragma solidity ^0.8.0;

import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../../libraries/logic/ReserveLogic.sol';
import '../../../libraries/EthAddressLib.sol';
import '../../../libraries/types/DataTypes.sol';
import '../../../libraries/state/State.sol';

abstract contract EscrowStorage is State {
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

    function _eligibleAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) internal view returns (uint256, uint40) {
        DataTypes.Deposit[] storage deposits;
        uint40 lastUpdateTime;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            deposits = _juniorDepositRecords[_reserve][_user];
        } else {
            deposits = _seniorDepositRecords[_reserve][_user];
        }
        uint256 eligibleAmount = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (
                uint40(block.timestamp) - deposits[i].depositTime >
                _lockupTimeInSeconds
            ) {
                eligibleAmount += deposits[i].amount;
                lastUpdateTime = deposits[i].depositTime;
            }
        }
        return (eligibleAmount, lastUpdateTime);
    }

    function _overallAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) internal view returns (uint256) {
        DataTypes.Deposit[] storage deposits;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            deposits = _juniorDepositRecords[_reserve][_user];
        } else {
            deposits = _seniorDepositRecords[_reserve][_user];
        }
        uint256 overallAmount = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            overallAmount += deposits[i].amount;
        }
        return overallAmount;
    }
}

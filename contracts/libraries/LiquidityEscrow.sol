// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import './EthAddressLib.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import './logic/ReserveLogic.sol';

contract LiquidityEscrow is ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for ERC20;

    struct Deposit {
        uint256 amount;
        uint40 depositTime;
    }

    event Deposited(
        address indexed payee,
        address token,
        uint256 amount,
        uint256 recordAmount
    );
    event Withdrawn(address indexed payee, address token, uint256 amount);

    // reserve address => amount
    mapping(address => uint256) private _deposits;
    // reserve address => user address => junior deposit record
    mapping(address => mapping(address => Deposit[]))
        private _juniorDepositRecords;
    // reserve address => user address => senior deposit record
    mapping(address => mapping(address => Deposit[]))
        private _seniorDepositRecords;

    uint40 private _lockupTimeInSeconds = 7 days;

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param _reserve the asset address
     * @param _user user address who deposit to this escrow
     * @param _amount token amount need to transfer
     * @param _recordAmount token amount that will be recored
     */
    function _deposit(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address _user,
        uint256 _amount,
        uint256 _recordAmount
    ) internal {
        if (_reserve != EthAddressLib.ethAddress()) {
            require(
                msg.value == 0,
                'User is sending ETH along with the ERC20 transfer.'
            );
            ERC20(_reserve).safeTransferFrom(_user, address(this), _amount);
        } else {
            require(
                msg.value == _amount,
                'The amount and the value sent to deposit do not match'
            );
        }
        _deposits[_reserve] += _recordAmount;
        Deposit memory deposit = Deposit(
            _recordAmount,
            uint40(block.timestamp)
        );
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            _juniorDepositRecords[_reserve][_user].push(deposit);
        } else {
            _seniorDepositRecords[_reserve][_user].push(deposit);
        }
        emit Deposited(_user, _reserve, _amount, _recordAmount);
    }

    function eligibleAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) public view returns (uint256) {
        (uint256 eligibleAmt, uint40 lastUpdateTime) = _eligibleAmount(
            _reserve,
            _user,
            _tranche
        );
        return eligibleAmt;
    }

    function overallAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) public view returns (uint256) {
        return _overallAmount(_reserve, _user, _tranche);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, only beyond _lockupTimeInSeconds
     * @param _reserve the asset address
     * @param _user user address who deposit to this escrow
     */
    function _withdraw(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address payable _user,
        uint256 _amount
    ) internal {
        (uint256 eligibleAmount, uint40 lastUpdateTime) = _eligibleAmount(
            _reserve,
            _user,
            _tranche
        );

        require(
            eligibleAmount >= _amount,
            'Do not have enough amount to withdraw'
        );
        // if there is any amount left from eligible amount, push it back
        if (eligibleAmount > _amount) {
            uint256 leftAmount = eligibleAmount - _amount;
            Deposit memory leftDeposit = Deposit(leftAmount, lastUpdateTime);
            if (ReserveLogic.Tranche.JUNIOR == _tranche) {
                _juniorDepositRecords[_reserve][_user].push(leftDeposit);
            } else {
                _seniorDepositRecords[_reserve][_user].push(leftDeposit);
            }
        }
        _deposits[_reserve] -= _amount;
        transferToUser(_reserve, _user, _amount);
        emit Withdrawn(_user, _reserve, _amount);
    }

    /**
     * @dev get accumulated amount of deposit.
     * @param _reserve the address of the reserve where the transfer is happening
     * @return accumulated deposit amount
     **/
    function getDepositAmount(address _reserve) public view returns (uint256) {
        return _deposits[_reserve];
    }

    /**
     * @dev get all records of deposit.
     * @param _reserve the address of the reserve where the transfer is happening
     * @param _tranche the tranche of the reserve
     * @param _user the address of the user receiving the transfer
     * @return deposit records
     **/
    function getDepositRecords(
        address _reserve,
        ReserveLogic.Tranche _tranche,
        address _user
    ) public view returns (Deposit[] memory) {
        Deposit[] storage deposits;
        if (ReserveLogic.Tranche.JUNIOR == _tranche) {
            deposits = _juniorDepositRecords[_reserve][_user];
        } else {
            deposits = _juniorDepositRecords[_reserve][_user];
        }
        return deposits;
    }

    /**
     * @dev transfers to the user a specific amount from the reserve.
     * @param _reserve the address of the reserve where the transfer is happening
     * @param _user the address of the user receiving the transfer
     * @param _amount the amount being transferred
     **/
    function transferToUser(
        address _reserve,
        address payable _user,
        uint256 _amount
    ) internal {
        if (_reserve != EthAddressLib.ethAddress()) {
            ERC20(_reserve).safeTransfer(_user, _amount);
        } else {
            //solium-disable-next-line
            (bool result, ) = _user.call{value: _amount}('');
            require(result, 'Transfer of ETH failed');
        }
    }

    function _eligibleAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) internal view returns (uint256, uint40) {
        Deposit[] storage deposits;
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
        Deposit[] storage deposits;
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

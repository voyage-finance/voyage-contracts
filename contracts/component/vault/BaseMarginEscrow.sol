// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EthAddressLib} from "../../libraries/EthAddressLib.sol";

contract BaseMarginEscrow is ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for ERC20;

    struct Deposit {
        uint256 amount;
        uint40 depositTime;
    }

    event Deposited(address indexed payee, address token, uint256 amount);
    event Withdrawn(address indexed payee, address token, uint256 amount);

    // reserve address => amount
    mapping(address => uint256) private _deposits;
    // reserve address => user address => deposit record
    mapping(address => mapping(address => Deposit[])) private _depositRecords;

    uint40 private _lockupTimeInSeconds = 7 days;

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param _reserve the asset address
     * @param _user user address who deposit to this escrow
     * @param _amount token amount need to transfer
     */
    function _deposit(
        address _reserve,
        address _user,
        uint256 _amount
    ) internal {
        if (_reserve != EthAddressLib.ethAddress()) {
            require(
                msg.value == 0,
                "User is sending ETH along with the ERC20 transfer."
            );
            ERC20(_reserve).safeTransferFrom(_user, address(this), _amount);
        } else {
            require(
                msg.value == _amount,
                "The amount and the value sent to deposit do not match"
            );
        }
        _deposits[_reserve] += _amount;
        Deposit memory deposit = Deposit(_amount, uint40(block.timestamp));
        _depositRecords[_reserve][_user].push(deposit);
        emit Deposited(_user, _reserve, _amount);
    }

    function eligibleAmount(address _reserve, address _user)
        public
        view
        returns (uint256)
    {
        Deposit[] storage deposits = _depositRecords[_reserve][_user];
        uint256 eligibleAmount = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (
                uint40(block.timestamp) - deposits[i].depositTime >
                _lockupTimeInSeconds
            ) {
                eligibleAmount += deposits[i].amount;
            }
        }
        return eligibleAmount;
    }

    /**
     * @dev Withdraw accumulated balance for a payee, only beyond _lockupTimeInSeconds
     * @param _reserve the asset address
     * @param _user user address who deposit to this escrow
     */
    function _withdraw(
        address _reserve,
        address payable _user,
        uint256 _amount
    ) internal {
        Deposit[] storage deposits = _depositRecords[_reserve][_user];
        uint256 eligibleAmount = 0;
        uint40 lastUpdateTime;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (
                uint40(block.timestamp) - deposits[i].depositTime >
                _lockupTimeInSeconds
            ) {
                eligibleAmount += deposits[i].amount;
                lastUpdateTime = deposits[i].depositTime;
                delete deposits[i];
            }
        }

        require(
            eligibleAmount >= _amount,
            "Do not have enough amount to withdraw"
        );
        // todo check borrow amount
        // if there is any amount left from eligible amount, push it back
        if (eligibleAmount > _amount) {
            uint256 leftAmount = eligibleAmount - _amount;
            Deposit memory leftDeposit = Deposit(leftAmount, lastUpdateTime);
            _depositRecords[_reserve][_user].push(leftDeposit);
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
     * @param _user the address of the user receiving the transfer
     * @return deposit records
     **/
    function getDepositRecords(address _reserve, address _user)
        public
        view
        returns (Deposit[] memory)
    {
        Deposit[] storage deposits = _depositRecords[_reserve][_user];
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
            (bool result, ) = _user.call{value: _amount}("");
            require(result, "Transfer of ETH failed");
        }
    }
}

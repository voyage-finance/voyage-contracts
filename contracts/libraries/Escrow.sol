// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/Ownable.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import './EthAddressLib.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';

contract Escrow is Ownable, ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for ERC20;

    struct Deposit {
        uint256 amount;
        uint40 depositTime;
    }

    event Deposited(address indexed payee, address token, uint256 amount);
    event Withdrawn(address indexed payee, address token, uint256 amount);

    // reserve address => payee => amount
    mapping(address => mapping(address => uint256)) private _deposits;
    // reserve address => payee => deposit record
    mapping(address => mapping(address => Deposit[])) private _depositRecords;


    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param _reserve the asset address
     * @param _user user address who deposit to this escrow
     * @param _amount token amount
     */
    function deposit(
        address _reserve,
        address _user,
        uint256 _amount
    ) external payable nonReentrant onlyOwner {
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
        _deposits[_reserve][_user] += _amount;
        Deposit memory deposit = Deposit(_amount, uint40(block.timestamp));
        _depositRecords[_reserve][_user].push(deposit);
    }
}

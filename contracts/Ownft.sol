// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.9;

import './libraries/ownership/Ownable.sol';
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Ownft is Ownable {
    // last_update_time will be updated when deposit/claim happens
    struct DepositInfo {
        address user;
        uint principal;
        uint last_update_time;
    }

    using Address for address;
    using SafeERC20 for ERC20;

    mapping(address => bool) _depositWhitelist;

    mapping(address => DepositInfo) _depositInfo;

    constructor() public {}

    // set up assets that can be deposited
    function setDepositWhiteList(
        address token,
        bool enable
    ) onlyOwner public returns(uint) {
        _depositWhitelist[token] = enable;
        return 0;
    }

    function deposit(
        address token,
        uint amount
    ) public {
        require(_depositWhitelist[token] == true, 'Ownft: TOKEN NOT ENABLED');
        ERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        // update user state
    }
}
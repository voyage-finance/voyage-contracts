// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.9;

import './libraries/ownership/Ownable.sol';
import './libraries/utils/Address.sol';

contract Ownft is Ownable {
    using Address for address;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));


    mapping(address => bool) _depositWhitelist;

    constructor() public {}

    function _safeTransfer(
        address token,
        address to,
        uint value
    ) private {
       (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
       require(success && (data.length == 0 || abi.decode(data, (bool))), 'Ownft: TRANSFER_FAILED');
    }

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

    }
}
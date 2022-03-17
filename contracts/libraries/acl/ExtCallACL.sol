// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../proxy/Proxyable.sol';

contract ExtCallACL is Proxyable {
    mapping(address => bool) public whitelistedAddress;
    mapping(string => bool) public whitelistedFunctions;

    constructor(address payable _proxy) public Proxyable(_proxy) {}

    function whitelistAddress(address _address) external onlyOwner {
        whitelistedAddress[_address] = true;
    }

    function blockAddress(address _address) external onlyOwner {
        delete whitelistedAddress[_address];
    }

    function isWhitelistedAddress(address _address)
        external
        view
        returns (bool)
    {
        return whitelistedAddress[_address];
    }
}

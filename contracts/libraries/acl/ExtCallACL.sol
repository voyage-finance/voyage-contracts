// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../proxy/Proxyable.sol';
import './IExtCallACL.sol';

contract ExtCallACL is Proxyable, IExtCallACL {
    mapping(address => bool) public whitelistedAddress;
    mapping(bytes32 => bool) public whitelistedFunctions;

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

    function whitelistFunction(bytes32 _func) external onlyOwner {
        whitelistedFunctions[_func] = true;
    }

    function blockFunction(bytes32 _func) external onlyOwner {
        delete whitelistedFunctions[_func];
    }

    function isWhitelistedFunction(bytes32 _func) external view returns (bool) {
        return whitelistedFunctions[_func];
    }
}

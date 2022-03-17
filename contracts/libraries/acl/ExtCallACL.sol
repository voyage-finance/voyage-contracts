// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../proxy/Proxyable.sol';
import './IExtCallACL.sol';

contract ExtCallACL is Proxyable, IExtCallACL {
    mapping(address => bool) public whitelistedAddress;
    mapping(bytes32 => bool) public whitelistedFunctions;

    constructor(address payable _proxy) public Proxyable(_proxy) {}

    function whitelistAddress(address[] calldata _address) external onlyProxy {
        uint256 arrayLength = _address.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            whitelistedAddress[_address[i]] = true;
        }
    }

    function blockAddress(address[] calldata _address) external onlyProxy {
        uint256 arrayLength = _address.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            delete whitelistedAddress[_address[i]];
        }
    }

    function isWhitelistedAddress(address _address)
        external
        view
        returns (bool)
    {
        return whitelistedAddress[_address];
    }

    function whitelistFunction(bytes32[] calldata _func) external onlyProxy {
        uint256 arrayLength = _func.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            whitelistedFunctions[_func[i]] = true;
        }
    }

    function blockFunction(bytes32[] calldata _func) external onlyProxy {
        uint256 arrayLength = _func.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            delete whitelistedFunctions[_func[i]];
        }
    }

    function isWhitelistedFunction(bytes32 _func) external view returns (bool) {
        return whitelistedFunctions[_func];
    }
}

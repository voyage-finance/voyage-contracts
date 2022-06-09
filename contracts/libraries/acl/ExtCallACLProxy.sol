// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../proxy/Proxy.sol";
import "./IExtCallACL.sol";

contract ExtCallACLProxy is Proxy {
    function isWhitelistedAddress(address _address) public view returns (bool) {
        return IExtCallACL(address(target)).isWhitelistedAddress(_address);
    }

    function isWhitelistedFunction(bytes32 _func) public view returns (bool) {
        return IExtCallACL(address(target)).isWhitelistedFunction(_func);
    }
}

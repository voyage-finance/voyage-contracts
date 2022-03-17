// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IExtCallACL {
    function whitelistAddress(address[] calldata _address) external;

    function blockAddress(address[] calldata _address) external;

    function isWhitelistedAddress(address _address)
        external
        view
        returns (bool);

    function whitelistFunction(bytes32[] calldata _func) external;

    function blockFunction(bytes32[] calldata _func) external;

    function isWhitelistedFunction(bytes32 _func) external view returns (bool);
}

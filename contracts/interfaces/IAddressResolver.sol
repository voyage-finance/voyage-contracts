// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    //function getSynth(byte32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);
}

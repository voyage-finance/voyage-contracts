// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultFactory {
    function createVault(
        address owner,
        address voyage,
        uint256 version,
        bytes32 checksum,
        bytes32 salt
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultFactory {
    function createVault(
        address owner,
        address voyage,
        bytes32 salt
    ) external returns (address);
}

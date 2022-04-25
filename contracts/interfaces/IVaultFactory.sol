// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultFactory {
    function createVault(bytes32 _salt) external returns (address);
}

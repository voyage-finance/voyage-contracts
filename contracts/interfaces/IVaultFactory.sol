// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultFactory {
    function createVault(address _user) external returns (address);
}

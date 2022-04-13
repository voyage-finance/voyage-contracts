// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IACLManager {
    function isLiquidityManager(address _admin) external view returns (bool);

    function isVaultManager(address _admin) external view returns (bool);

    function isProtocolManager(address _admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IACLManager {
    function grantLiquidityManager(address _admin) external;

    function isLiquidityManager(address _admin) external view returns (bool);

    function grantVaultManager(address _admin) external;

    function isVaultManager(address _admin) external view returns (bool);

    function grantPoolManager(address _admin) external;

    function grantLoanManager(address _admin) external;

    function isLoanManager(address _admin) external view returns (bool);

    function isProtocolManager(address _admin) external view returns (bool);
}

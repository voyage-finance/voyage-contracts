// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultManager {
    function getMaxSecurityDeposit(address _reserve)
        external
        view
        returns (uint256);

    function getSecurityDepositRequirement(address _reserve)
        external
        view
        returns (uint256);

    function getCreditLimit(address _user, address _reserve)
        external
        view
        returns (uint256);

    function eligibleAmount(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) external view returns (uint256);

    function underlyingBalance(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) external view returns (uint256);

    function createVault(address _user) external returns (address vault);

    function getVault(address _user) external view returns (address);

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256);
}

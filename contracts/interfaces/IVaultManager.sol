// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultManager {
    event VaultCreated(address indexed user, address vault, uint256 len);

    event SecurityDeposited(
        address indexed sponsor,
        address user,
        address reserve,
        uint256 amount
    );

    event SecurityRedeemed(
        address indexed sponsor,
        address user,
        address reserve,
        uint256 amount
    );

    event SecurityDepositRequirementSet(
        address indexed reserve,
        uint256 requirement
    );

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
        public
        view
        returns (uint256);
}

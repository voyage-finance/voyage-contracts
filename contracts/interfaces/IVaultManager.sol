// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultManager {
    function getMaxSecurityDeposit(address _reserve)
        external
        view
        returns (uint256);

    function getMinSecurityDeposit(address _reserve)
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

    function createVault(
        address _user,
        address _reserve,
        bytes32 _vault
    ) external returns (address);

    function initVault(address _vault, address _reserve) external;

    function getVault(address _user) external view returns (address);

    function getAllVaults() external view returns (address[] memory);

    function getGav(address _user) external view returns (uint256);

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256);

    function getAvailableCredit(address _user, address _reserve)
        external
        view
        returns (uint256);
}

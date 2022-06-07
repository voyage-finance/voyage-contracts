// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IAddressResolver {
    event AddressImported(bytes32 name, address destination);

    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external;

    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);

    function getVoyage() external view returns (address);

    function getLiquidityManagerProxy() external view returns (address);

    function getLiquidityManagerStorage() external view returns (address);

    function getLoanManagerProxy() external view returns (address);

    function getLoanManager() external view returns (address);

    function getVaultManagerProxy() external view returns (address);

    function getVaultManager() external view returns (address);

    function getExtCallProxy() external view returns (address);

    function getAclManager() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getVaultStorage() external view returns (address);

    function getJuniorDepositToken() external view returns (address);

    function getSeniorDepositToken() external view returns (address);
}

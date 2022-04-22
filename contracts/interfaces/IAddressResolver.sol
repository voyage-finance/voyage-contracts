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

    function getLiquidityManagerProxy() external view returns (address);

    function getLiquidityDepositEscrow() external view returns (address);

    function getLoanManagerProxy() external view returns (address);

    function getLoanManager() external view returns (address);

    function getStableDebtToken() external view returns (address);
    
    function getVaultStorage() external view returns (address);
}

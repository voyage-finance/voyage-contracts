// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IAddressResolver} from "../../interfaces/IAddressResolver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AddressResolver is IAddressResolver, Ownable {
    bytes32 public constant voyageName = "voyager";
    bytes32 public constant aclManagerName = "aclManager";
    bytes32 public constant liquidityManagerProxyName = "liquidityManagerProxy";
    bytes32 public constant liquidityManagerName = "liquidityManager";
    bytes32 public constant liquidityManagerStorageName =
        "liquidityManagerStorage";
    bytes32 public constant liquidityDepositEscrowName =
        "liquidityDepositEscrow";
    bytes32 public constant loanManagerProxyName = "loanManagerProxy";
    bytes32 public constant loanManagerName = "loanManager";
    bytes32 public constant vaultManagerProxyName = "vaultManagerProxy";
    bytes32 public constant vaultManagerName = "vaultManager";
    bytes32 public constant vaultStorageName = "vaultStorage";
    bytes32 public constant juniorDepositTokenName = "juniorDepositToken";
    bytes32 public constant seniorDepositTokenName = "seniorDepositToken";
    bytes32 public constant securityDepositTokenName = "securityDepositToken";
    bytes32 public constant extCallACLProxyName = "extCallACLProxy";
    bytes32 public constant priceOracleName = "priceOracle";

    mapping(bytes32 => address) public repository;

    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external onlyOwner {
        require(
            names.length == destinations.length,
            "Input lengths must match"
        );

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    function getVoyage() external view returns (address) {
        return repository[voyageName];
    }

    function getLiquidityManagerProxy() external view returns (address) {
        return repository[liquidityManagerProxyName];
    }

    function getLiquidityManagerStorage() external view returns (address) {
        return repository[liquidityManagerStorageName];
    }

    function getLoanManagerProxy() external view returns (address) {
        return repository[loanManagerProxyName];
    }

    function getLoanManager() external view returns (address) {
        return repository[loanManagerName];
    }

    function getVaultManagerProxy() external view returns (address) {
        return repository[vaultManagerProxyName];
    }

    function getVaultManager() external view returns (address) {
        return repository[vaultManagerName];
    }

    function getVaultStorage() external view returns (address) {
        return repository[vaultStorageName];
    }

    function getJuniorDepositToken() external view returns (address) {
        return repository[juniorDepositTokenName];
    }

    function getSeniorDepositToken() external view returns (address) {
        return repository[seniorDepositTokenName];
    }

    function getExtCallProxy() external view returns (address) {
        return repository[extCallACLProxyName];
    }

    function getAclManager() external view returns (address) {
        return repository[aclManagerName];
    }

    function getPriceOracle() external view returns (address) {
        return repository[priceOracleName];
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address)
    {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }
}

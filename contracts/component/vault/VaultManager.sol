// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Vault.sol';
import '../../interfaces/IVaultManager.sol';

contract VaultManager {
    address[] public allVaults;

    // player address => vault address
    mapping(address => address) public getVault;

    event VaultCreated(address indexed player, address vault, uint256);

    function createAccount(address _player) external returns (address vault) {
        bytes memory bytecode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_player));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IVaultManager(vault).initialize(_player);
        allVaults.push(vault);
        getVault[_player] = vault;
        emit VaultCreated(_player, vault, allVaults.length);
    }

    function getCreditAccount(address _user) external view returns (address) {
        return getVault[_user];
    }

    function getAllCreditAccount() external view returns (address[] memory) {
        return allVaults;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Vault.sol';
import '../../interfaces/IVaultManager.sol';

contract VaultManager {
    address[] public allVaults;

    event VaultCreated(address indexed player, address vault, uint256);

    function createAccount(address _player) external returns (address vault) {
        bytes memory bytecode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_player));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IVaultManager(vault).initialize(_player);
        allVaults.push(vault);
        emit VaultCreated(_player, vault, allVaults.length);
    }
}

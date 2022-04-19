// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Vault.sol';
import '../../interfaces/IVaultFactory.sol';

contract VaultFactory is IVaultFactory {
    function createVault(address _user) external returns (address) {
        bytes memory bytecode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_user));
        address vault;
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        return vault;
    }
}

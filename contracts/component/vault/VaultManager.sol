// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Vault.sol';
import '../../interfaces/IVaultManager.sol';
import '../Voyager.sol';
import '../infura/AddressResolver.sol';
import './VaultStorage.sol';

contract VaultManager {
    address public voyager;

    event VaultCreated(address indexed player, address vault, uint256);

    modifier onlyVoyager() {
        require(voyager == msg.sender, 'The caller must be a voyager');
        _;
    }

    constructor(address _voyager) public {
        voyager = _voyager;
    }

    function getVaultStorageAddress() private returns (address) {
        Voyager v = Voyager(voyager);
        address resolver = v.getAddressResolverAddress();
        return AddressResolver(resolver).getAddress(v.getVaultStorageName());
    }

    /**
     * @dev Create a credit account
     * @param _player the address of the player
     **/
    function createAccount(address _addressResolver, address _player)
        external
        onlyVoyager
        returns (address vault)
    {
        bytes memory bytecode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_player));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IVaultManager(vault).initialize(_player);
        uint256 len = VaultStorage(getVaultStorageAddress()).pushNewVault(
            _player,
            vault
        );
        emit VaultCreated(_player, vault, len);
    }
}

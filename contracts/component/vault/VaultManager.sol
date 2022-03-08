// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Vault.sol';
import '../../interfaces/IVaultManager.sol';
import '../Voyager.sol';
import '../infura/AddressResolver.sol';
import './VaultStorage.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';

contract VaultManager is AccessControl, ReentrancyGuard {
    using SafeERC20 for ERC20;

    bytes32 public constant VOYAGER = keccak256('VOYAGER');
    address public voyager;

    event VaultCreated(address indexed player, address vault, uint256);

    constructor(address _voyager) public {
        voyager = _voyager;
        _setupRole(VOYAGER, _voyager);
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
    function createVault(address _player)
        external
        onlyRole(VOYAGER)
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

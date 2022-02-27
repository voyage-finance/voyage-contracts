// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Vault.sol';
import '../../interfaces/IVaultManager.sol';

contract VaultManager {
    address[] public allVaults;

    // player address => vault address
    mapping(address => address) public getVault;

    address public voyager;

    event VaultCreated(address indexed player, address vault, uint256);

    modifier onlyVoyager() {
        require(voyager == msg.sender, 'The caller must be a voyager');
        _;
    }

    constructor(address _voyager) public {
        voyager = _voyager;
    }

    /**
     * @dev Create a credit account
     * @param _player the address of the player
     **/
    function createAccount(address _player)
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
        allVaults.push(vault);
        getVault[_player] = vault;
        emit VaultCreated(_player, vault, allVaults.length);
    }

    /**
     * @dev Get credit account address for a specific user
     * @param _user the address of the player
     **/
    function getCreditAccount(address _user) external view returns (address) {
        return getVault[_user];
    }

    /**
     * @dev Get all credit account addresses
     **/
    function getAllCreditAccount() external view returns (address[] memory) {
        return allVaults;
    }
}

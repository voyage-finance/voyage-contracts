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
    mapping(address => uint256) public maxSecurityDeposit;

    event VaultCreated(address indexed player, address vault, uint256);

    constructor(address _voyager) public {
        voyager = _voyager;
        _setupRole(VOYAGER, _voyager);
    }

    function getVaultStorageAddress() private view returns (address) {
        Voyager v = Voyager(voyager);
        address resolver = v.getAddressResolverAddress();
        return AddressResolver(resolver).getAddress(v.getVaultStorageName());
    }

    /**
     * @dev Create a Vault for user
     * @param _user the address of the player
     **/
    function createVault(address _user)
        external
        onlyRole(VOYAGER)
        returns (address vault)
    {
        bytes memory bytecode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_user));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        Vault(vault).initialize(
            Voyager(voyager).getAddressResolverAddress(),
            _user
        );
        uint256 len = VaultStorage(getVaultStorageAddress()).pushNewVault(
            _user,
            vault
        );
        emit VaultCreated(_user, vault, len);
    }

    /**
     * @dev Get existing Vault contract address for user
     * @param _user the address of the player
     * @return Vault address
     **/
    function getVault(address _user)
        external
        view
        onlyRole(VOYAGER)
        returns (address)
    {
        return VaultStorage(getVaultStorageAddress()).getVaultAddress(_user);
    }

    /************************ HouseKeeping Function ******************************/

    function setMaxSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyRole(VOYAGER)
    {
        maxSecurityDeposit[_reserve] = _amount;
    }

    function removeMaxSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyRole(VOYAGER)
    {
        delete maxSecurityDeposit[_reserve];
    }

    function getMaxSecurityDeposit(address _reserve)
        external
        view
        returns (uint256)
    {
        return maxSecurityDeposit[_reserve];
    }
}

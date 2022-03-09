// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/ownership/Ownable.sol';
import '../component/infura/AddressResolver.sol';
import '../component/vault/VaultManager.sol';

contract Voyager is Ownable {
    bytes32 public constant liquidityManagerName = 'liquidityManager';
    bytes32 public constant loanManagerName = 'loanManager';
    bytes32 public constant vaultManagerName = 'vaultManager';
    bytes32 public constant vaultStorageName = 'vaultStorage';

    address public addressResolver;

    /**
     * @dev Update addressResolver contract address
     * @param _addressResolver address of the resolver contract
     **/
    function setAddressResolverAddress(address _addressResolver)
        external
        onlyOwner
    {
        addressResolver = _addressResolver;
    }

    /**
     * @dev Get addressResolver contract address
     * @return address of the resolver contract
     **/
    function getAddressResolverAddress() external view returns (address) {
        return addressResolver;
    }

    function getVaultManagerName() external view returns (bytes32) {
        return vaultManagerName;
    }

    function getVaultStorageName() external view returns (bytes32) {
        return vaultStorageName;
    }

    function getLiquidityManagerName() external view returns (bytes32) {
        return liquidityManagerName;
    }

    function getLoanManagerName() external view returns (bytes32) {
        return loanManagerName;
    }

    function getVaultManagerAddress() public returns (address) {
        return AddressResolver(addressResolver).getAddress(vaultManagerName);
    }

    /**
     * @dev Create an empty Vault for msg.sender, in addition to this, a vault also deploy
     * a SecurityDepositEscrow contract which the fund will be held in
     × @return address of Vault
     **/
    function createVault() external returns (address) {
        return VaultManager(getVaultManagerAddress()).createVault(msg.sender);
    }
}

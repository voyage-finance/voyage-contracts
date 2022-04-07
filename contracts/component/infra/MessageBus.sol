// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './AddressResolver.sol';
import '../../interfaces/IMessageBus.sol';
import '../../interfaces/IVaultManager.sol';
import '../../libraries/ownership/Ownable.sol';

/**
 * todo it might be a bad name here, it actually performs as the centralise place
 * for querying each other among the internal components
 **/
contract MessageBus is IMessageBus, Ownable {
    bytes32 public constant liquidityManagerProxyName = 'liquidityManagerProxy';
    bytes32 public constant liquidityManagerName = 'liquidityManager';
    bytes32 public constant liquidityManagerStorageName =
        'liquidityManagerStorage';
    bytes32 public constant loanManagerName = 'loanManager';
    bytes32 public constant vaultManagerProxyName = 'vaultManagerProxy';
    bytes32 public constant vaultStorageName = 'vaultStorage';
    bytes32 public constant securityDepositTokenName = 'securityDepositToken';
    bytes32 public constant extCallACLProxyName = 'extCallACLProxy';

    AddressResolver public addressResolver;

    /**
     * @dev Get addressResolver contract address
     * @return address of the resolver contract
     **/
    function getAddressResolverAddress() external view returns (address) {
        return address(addressResolver);
    }

    /************************************** LiquidityManager Functions **************************************/

    /**
     * @dev Get LiquidityManagerProxy contract address
     **/
    function getLiquidityManagerProxyAddress()
        public
        view
        returns (address payable)
    {
        address liquidityManagerProxyAddress = addressResolver.getAddress(
            liquidityManagerProxyName
        );
        return payable(liquidityManagerProxyAddress);
    }

    /************************************** Vault Functions **************************************/

    /**
     * @dev Get vault address
     * @param _user The owner of the vault
     **/
    function getVault(address _user) external view returns (address) {
        return IVaultManager(getVaultManagerProxyAddress()).getVault(_user);
    }

    /**
     * @dev Get max security deposit for _reserve
     * @param _reserve reserve address
     * @return max deposit amount
     */
    function getMaxSecurityDeposit(address _reserve)
        external
        view
        returns (uint256)
    {
        return
            IVaultManager(getVaultManagerProxyAddress()).getMaxSecurityDeposit(
                _reserve
            );
    }

    /**
     * @dev Get current security deposit requirement
     * @param _reserve reserve address
     * @return requirement, expressed in Ray
     **/
    function getSecurityDepositRequirement(address _reserve)
        external
        view
        returns (uint256)
    {
        return
            IVaultManager(getVaultManagerProxyAddress())
                .getSecurityDepositRequirement(_reserve);
    }

    /**
     * @dev Get VaultManagerProxy contract address
     * @return address of the VaultManager
     **/
    function getVaultManagerProxyAddress()
        public
        view
        returns (address payable)
    {
        address vaultManagerProxyAddress = addressResolver.getAddress(
            vaultManagerProxyName
        );
        return payable(vaultManagerProxyAddress);
    }

    /************************************** Constant Functions **************************************/

    function getVaultManagerProxyName() external view returns (bytes32) {
        return vaultManagerProxyName;
    }

    function getVaultStorageName() external view returns (bytes32) {
        return vaultStorageName;
    }

    function getLiquidityManagerProxyName() external view returns (bytes32) {
        return liquidityManagerProxyName;
    }

    function getLiquidityManagerStorageName() external view returns (bytes32) {
        return liquidityManagerStorageName;
    }

    function getLoanManagerName() external view returns (bytes32) {
        return loanManagerName;
    }

    function getSecurityDepositTokenName() external view returns (bytes32) {
        return securityDepositTokenName;
    }

    function getExtCallACLProxyName() external view returns (bytes32) {
        return extCallACLProxyName;
    }
}

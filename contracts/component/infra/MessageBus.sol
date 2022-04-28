// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './AddressResolver.sol';
import '../../interfaces/IMessageBus.sol';
import '../../interfaces/IStableDebtToken.sol';
import '../../interfaces/IVaultManager.sol';
import '../../libraries/ownership/Ownable.sol';
import '../../libraries/types/DataTypes.sol';
import '../../libraries/helpers/Errors.sol';
import '../liquidity/LiquidityManager.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import '../vault/VaultManager.sol';
import '../vault/VaultManagerProxy.sol';

/**
 * todo it might be a bad name here, it actually performs as the centralise place
 * for querying each other among the internal components
 **/
contract MessageBus is IMessageBus, Ownable {
    // todo to remove
    bytes32 public constant aclManagerName = 'aclManager';
    bytes32 public constant liquidityManagerProxyName = 'liquidityManagerProxy';
    bytes32 public constant liquidityManagerName = 'liquidityManager';
    bytes32 public constant liquidityManagerStorageName =
        'liquidityManagerStorage';
    bytes32 public constant loanManagerName = 'loanManager';
    bytes32 public constant vaultManagerProxyName = 'vaultManagerProxy';
    bytes32 public constant vaultManagerName = 'vaultManager';
    bytes32 public constant vaultStorageName = 'vaultStorage';
    bytes32 public constant securityDepositTokenName = 'securityDepositToken';
    bytes32 public constant stableDebtTokenName = 'stableDebtToken';
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

    /**
     * @dev Returns the state and configuration of the reserve
     * @param _asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address _asset)
        external
        view
        returns (DataTypes.ReserveData memory)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManager(getLiquidityManagerProxyAddress()).getReserveData(
                _asset
            );
    }

    /************************************** Vault Functions **************************************/

    /**
     * @dev Get vault address
     * @param _user The owner of the vault
     **/
    function getVault(address _user) external view returns (address) {
        return VaultManagerProxy(getVaultManagerProxyAddress()).getVault(_user);
    }

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        uint256 amt = VaultManagerProxy(getVaultManagerProxyAddress())
            .getSecurityDeposit(_user, _reserve);
        return amt;
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

    /************************************** Stable Debt Token Functions **************************************/

    function getCompoundedDebt(address _user) external view returns (uint256) {
        return
            IERC20(addressResolver.getAddress(stableDebtTokenName)).balanceOf(
                _user
            );
    }

    function getAggregateOptimalRepaymentRate(address _user)
        external
        view
        returns (uint256)
    {
        return
            IStableDebtToken(addressResolver.getAddress(stableDebtTokenName))
                .getAggregateOptimalRepaymentRate(_user);
    }

    function getAggregateActualRepaymentRate(address _user)
        external
        view
        returns (uint256)
    {
        return
            IStableDebtToken(addressResolver.getAddress(stableDebtTokenName))
                .getAggregateActualRepaymentRate(_user);
    }

    /************************************** Constant Functions **************************************/

    function getVaultManagerProxyName() external view returns (bytes32) {
        return vaultManagerProxyName;
    }

    function getVaultManagerName() external view returns (bytes32) {
        return vaultManagerName;
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

    function getACLManagerName() external view returns (bytes32) {
        return aclManagerName;
    }

    function getStableDebtTokenName() external view returns (bytes32) {
        return stableDebtTokenName;
    }
}

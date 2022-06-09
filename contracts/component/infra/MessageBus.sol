// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./AddressResolver.sol";
import "../../interfaces/IMessageBus.sol";
import "../../interfaces/IVaultManager.sol";
import "../../libraries/ownership/Ownable.sol";
import "../../libraries/types/DataTypes.sol";
import "../../libraries/helpers/Errors.sol";
import "../liquidity/LiquidityManager.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {VaultManager} from "../vault/VaultManager.sol";
import "../vault/VaultManagerProxy.sol";

/**
 * todo it might be a bad name here, it actually performs as the centralise place
 * for querying each other among the internal components
 **/
contract MessageBus is IMessageBus, Ownable {
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
        address liquidityManagerProxyAddress = addressResolver
            .getLiquidityManagerProxy();
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

    function getVaultConfig(address _reserve)
        external
        view
        returns (DataTypes.VaultConfig memory)
    {
        require(Address.isContract(_reserve), Errors.LM_NOT_CONTRACT);
        return
            VaultManagerProxy(getVaultManagerProxyAddress()).getVaultConfig(
                _reserve
            );
    }

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
     * @dev Get VaultManagerProxy contract address
     * @return address of the VaultManager
     **/
    function getVaultManagerProxyAddress()
        public
        view
        returns (address payable)
    {
        address vaultManagerProxyAddress = addressResolver
            .getVaultManagerProxy();
        return payable(vaultManagerProxyAddress);
    }
}

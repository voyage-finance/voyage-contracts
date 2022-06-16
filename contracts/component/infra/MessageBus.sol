// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AddressResolver} from "./AddressResolver.sol";
import {IMessageBus} from "../../interfaces/IMessageBus.sol";
import {IVaultManager} from "../../interfaces/IVaultManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Storage, ADDRESS_RESOLVER} from "../../libraries/LibAppStorage.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {VaultManager} from "../vault/VaultManager.sol";
import {VaultManagerProxy} from "../vault/VaultManagerProxy.sol";

/**
 * todo it might be a bad name here, it actually performs as the centralise place
 * for querying each other among the internal components
 **/
contract MessageBus is Storage, IMessageBus {
    /************************************** LiquidityManager Functions **************************************/

    /**
     * @dev Get addressResolver contract address
     * @return address of the resolver contract
     **/
    function addressResolver()
        external
        view
        override
        returns (AddressResolver)
    {
        return AddressResolver(_addressResolver());
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
        address vaultManagerProxyAddress = this
            .addressResolver()
            .getVaultManagerProxy();
        return payable(vaultManagerProxyAddress);
    }
}

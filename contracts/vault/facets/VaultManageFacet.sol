// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CustodyData, VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {ISubvault} from "../interfaces/ISubvault.sol";
import {VaultConfig} from "../../voyage/libraries/LibAppStorage.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";
import {SecurityFacet} from "../../voyage/facets/SecurityFacet.sol";
import {VaultAuth} from "../libraries/LibAuth.sol";

contract VaultManageFacet is ReentrancyGuard, Storage, VaultAuth {
    /// @notice Create sub vault
    /// @param _owner The address of the owner
    function createSubvault(address _owner)
        external
        authorised
        returns (address)
    {
        BeaconProxy proxy = new BeaconProxy(
            address(VaultFacet(LibVaultStorage.ds().voyage).subVaultBeacon()),
            abi.encodeWithSelector(
                ISubvault(address(0)).initialize.selector,
                _owner,
                address(this)
            )
        );
        address subvault = address(proxy);
        if (subvault == address(0)) {
            revert FailedDeploySubvaultBeacon();
        }
        LibVaultStorage.ds().subvaults.push(subvault);
        LibVaultStorage.ds().subvaultOwnerIndex[subvault] = _owner;
        LibVaultStorage.ds().ownerSubvaultIndex[_owner] = subvault;
        LibVaultStorage.ds().subvaultStatusIndex[subvault] = false;
        SecurityFacet sf = SecurityFacet(LibVaultStorage.ds().voyage);
        sf.grantPermission(
            _owner,
            subvault,
            ISubvault(address(0)).callExternal.selector
        );
        return subvault;
    }

    /// @notice Update subvault's owner
    /// @param _subvault The address of the subvaault
    /// @param _newOwner The address of the new owner
    function updateSubvaultOwner(address _subvault, address _newOwner)
        external
        authorised
    {
        address oldOwner = LibVaultStorage.ds().subvaultOwnerIndex[_subvault];
        if (oldOwner == address(0)) {
            revert InvalidSubvaultAddress(_subvault);
        }
        ISubvault(_subvault).updateOwner(_newOwner);
        LibVaultStorage.ds().subvaultOwnerIndex[_subvault] = _newOwner;
        LibVaultStorage.ds().ownerSubvaultIndex[_newOwner] = _subvault;
        delete LibVaultStorage.ds().ownerSubvaultIndex[oldOwner];
    }

    /// @notice Pause sub vault
    /// @param _subvault The address of the subvault
    function pauseSubvault(address _subvault) external authorised {
        if (LibVaultStorage.ds().subvaultOwnerIndex[_subvault] == address(0)) {
            revert InvalidSubvaultAddress(_subvault);
        }
        LibVaultStorage.ds().subvaultStatusIndex[_subvault] = true;
    }

    /// @notice Uppause the sub vault
    /// @param _subvault The address of the subvault
    function unpauseSubvault(address _subvault) external authorised {
        if (LibVaultStorage.ds().subvaultOwnerIndex[_subvault] == address(0)) {
            revert InvalidSubvaultAddress(_subvault);
        }
        LibVaultStorage.ds().subvaultStatusIndex[_subvault] = false;
    }

    function callSubVault(
        address _subvault,
        address _target,
        bytes calldata _data
    ) external {
        SecurityFacet sf = SecurityFacet(LibVaultStorage.ds().voyage);
        if (
            !sf.isAuthorised(
                msg.sender,
                _subvault,
                ISubvault(address(0)).callExternal.selector
            )
        ) {
            revert UnAuthorised();
        }

        ISubvault(_subvault).callExternal(_target, _data);
    }

    function onERC721Transferred(
        address _collection,
        uint256 _tokenId,
        address _src,
        address _dst
    ) external {
        if (
            msg.sender != address(this) &&
            LibVaultStorage.ds().subvaultOwnerIndex[msg.sender] == address(0)
        ) {
            revert InvalidTransfer("invalid sender");
        }
        if (
            LibVaultStorage.ds().custodyIndex[_collection][_tokenId].owner !=
            address(0)
        ) {
            revert InvalidTransfer("invalid token id");
        }
        LibVaultStorage.ds().custodyIndex[_collection][_tokenId].owner = _src;
        LibVaultStorage.ds().tokenSet[_collection].push(_tokenId);
    }
}

/* --------------------------------- errors -------------------------------- */
error FailedDeploySubvaultBeacon();
error InvalidTransfer(string reason);
error InvalidSubvaultAddress(address subvault);
error UnAuthorised();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CustodyData, VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {IMarginEscrow} from "../interfaces/IMarginEscrow.sol";
import {ISubvault} from "../interfaces/ISubvault.sol";
import {VaultConfig} from "../../voyage/libraries/LibAppStorage.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";
import {SecurityFacet} from "../../voyage/facets/SecurityFacet.sol";

contract VaultManageFacet is ReentrancyGuard, Storage {
    /// @notice Create sub vault
    /// @param _owner The address of the owner
    function createSubvault(address _owner)
        external
        authorised
        returns (address)
    {
        BeaconProxy proxy = new BeaconProxy(
            address(
                VaultFacet(LibVaultStorage.diamondStorage().voyage)
                    .subVaultBeacon()
            ),
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
        LibVaultStorage.diamondStorage().subvaults.push(subvault);
        LibVaultStorage.diamondStorage().subvaultOwnerIndex[subvault] = _owner;
        LibVaultStorage.diamondStorage().ownerSubvaultIndex[_owner] = subvault;
        LibVaultStorage.diamondStorage().subvaultStatusIndex[subvault] = false;
        SecurityFacet sf = SecurityFacet(
            LibVaultStorage.diamondStorage().voyage
        );
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
        address oldOwner = LibVaultStorage.diamondStorage().subvaultOwnerIndex[
            _subvault
        ];
        if (oldOwner == address(0)) {
            revert InvalidSubvaultAddress(_subvault);
        }
        ISubvault(_subvault).updateOwner(_newOwner);
        LibVaultStorage.diamondStorage().subvaultOwnerIndex[
            _subvault
        ] = _newOwner;
        LibVaultStorage.diamondStorage().ownerSubvaultIndex[
            _newOwner
        ] = _subvault;
        delete LibVaultStorage.diamondStorage().ownerSubvaultIndex[oldOwner];
    }

    /// @notice Pause sub vault
    /// @param _subvault The address of the subvault
    function pauseSubvault(address _subvault) external authorised {
        if (
            LibVaultStorage.diamondStorage().subvaultOwnerIndex[_subvault] ==
            address(0)
        ) {
            revert InvalidSubvaultAddress(_subvault);
        }
        LibVaultStorage.diamondStorage().subvaultStatusIndex[_subvault] = true;
    }

    /// @notice Uppause the sub vault
    /// @param _subvault The address of the subvault
    function unpauseSubvault(address _subvault) external authorised {
        if (
            LibVaultStorage.diamondStorage().subvaultOwnerIndex[_subvault] ==
            address(0)
        ) {
            revert InvalidSubvaultAddress(_subvault);
        }
        LibVaultStorage.diamondStorage().subvaultStatusIndex[_subvault] = false;
    }

    function callSubVault(
        address _subvault,
        address target,
        bytes calldata data
    ) external {
        SecurityFacet sf = SecurityFacet(
            LibVaultStorage.diamondStorage().voyage
        );
        if (
            !sf.isAuthorised(
                msg.sender,
                _subvault,
                ISubvault(address(0)).callExternal.selector
            )
        ) {
            revert UnAuthorised();
        }

        ISubvault(_subvault).callExternal(target, data);
    }

    function onERC721Transferred(
        address _asset,
        uint256 _tokenId,
        address _src,
        address _dst
    ) external {
        if (
            msg.sender != address(this) &&
            LibVaultStorage.diamondStorage().subvaultOwnerIndex[msg.sender] ==
            address(0)
        ) {
            revert InvalidTransfer("invalid sender");
        }
        if (
            LibVaultStorage
            .diamondStorage()
            .custodyIndex[_asset][_tokenId].owner != address(0)
        ) {
            revert InvalidTransfer("invalid token id");
        }
        LibVaultStorage
        .diamondStorage()
        .custodyIndex[_asset][_tokenId].owner = _src;
        LibVaultStorage.diamondStorage().tokenSet[_asset].push(_tokenId);
    }

    modifier authorised() {
        SecurityFacet sf = SecurityFacet(
            LibVaultStorage.diamondStorage().voyage
        );
        if (!sf.isAuthorisedOutbound(address(this), msg.sig)) {
            revert UnAuthorised();
        }
        _;
    }
}

/* --------------------------------- errors -------------------------------- */
error FailedDeploySubvaultBeacon();
error InvalidTransfer(string reason);
error InvalidSubvaultAddress(address subvault);
error UnAuthorised();

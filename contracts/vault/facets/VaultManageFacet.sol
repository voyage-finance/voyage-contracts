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

contract VaultManageFacet is ReentrancyGuard, Storage {
    /// @notice Create sub vault
    /// @param _owner The address of the owner
    function createSubvault(address _owner)
        external
        onlyOwner
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
        require(
            subvault != address(0),
            "Vault#createSubvault: deploy vault beacon failed"
        );
        LibVaultStorage.diamondStorage().subvaults.push(subvault);
        LibVaultStorage.diamondStorage().subvaultOwnerIndex[subvault] = _owner;
        LibVaultStorage.diamondStorage().ownerSubvaultIndex[_owner] = subvault;
        LibVaultStorage.diamondStorage().subvaultStatusIndex[subvault] = false;
        return subvault;
    }

    /// @notice Update subvault's owner
    /// @param _subvault The address of the subvaault
    /// @param _newOwner The address of the new owner
    function updateSubvaultOwner(address _subvault, address _newOwner)
        external
        onlyOwner
    {
        address oldOwner = LibVaultStorage.diamondStorage().subvaultOwnerIndex[
            _subvault
        ];
        require(
            oldOwner != address(0),
            "Vault#updateSubvaultOwner: invalid subvault address"
        );
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
    function pauseSubvault(address _subvault) external onlyOwner {
        require(
            LibVaultStorage.diamondStorage().subvaultOwnerIndex[_subvault] !=
                address(0),
            "Vault#pauseSubvault: invalid subvault address"
        );
        LibVaultStorage.diamondStorage().subvaultStatusIndex[_subvault] = true;
    }

    /// @notice Uppause the sub vault
    /// @param _subvault The address of the subvault
    function unpauseSubvault(address _subvault) external onlyOwner {
        require(
            LibVaultStorage.diamondStorage().subvaultOwnerIndex[_subvault] !=
                address(0),
            "Vault#pauseSubvault: invalid subvault address"
        );
        LibVaultStorage.diamondStorage().subvaultStatusIndex[_subvault] = false;
    }

    function onERC721Transferred(
        address _asset,
        uint256 _tokenId,
        address _src,
        address _dst
    ) external {
        require(
            msg.sender == address(this) ||
                LibVaultStorage.diamondStorage().subvaultOwnerIndex[
                    msg.sender
                ] !=
                address(0),
            "Vault#onERC721Transferred: invalid sender"
        );
        require(
            LibVaultStorage
            .diamondStorage()
            .custodyIndex[_asset][_tokenId].owner == address(0),
            "Vault#onERC721Transferred: token id exists"
        );
        LibVaultStorage
        .diamondStorage()
        .custodyIndex[_asset][_tokenId].owner = _src;
        LibVaultStorage.diamondStorage().tokenSet[_asset].push(_tokenId);
    }
}

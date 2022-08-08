// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {LibAppStorage, AppStorage, Storage, VaultConfig, NFTInfo, DiamondFacet, ReserveConfigurationMap, MarketPlaceType} from "../libraries/LibAppStorage.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibSecurity} from "../libraries/LibSecurity.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {IVault} from "../../vault/interfaces/IVault.sol";
import {IExternalAdapter} from "../interfaces/IExternalAdapter.sol";
import {IDiamondVersionFacet, Snapshot} from "../interfaces/IDiamondVersionFacet.sol";
import {Vault} from "../../vault/Vault.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";
import {DiamondVersionFacet} from "./DiamondVersionFacet.sol";
import {VaultAssetFacet} from "../../vault/facets/VaultAssetFacet.sol";
import {VaultManageFacet} from "../../vault/facets/VaultManageFacet.sol";
import {VaultExternalFacet} from "../../vault/facets/VaultExternalFacet.sol";

contract VaultFacet is Storage, ReentrancyGuard {
    using LibReserveConfiguration for ReserveConfigurationMap;
    /* --------------------------------- events --------------------------------- */
    event VaultCreated(address _vault, address _owner, uint256 _numVaults);
    event VaultMarginCredited(
        address indexed _vault,
        address indexed _asset,
        address _sponsor,
        uint256 _amount
    );
    event VaultMarginRedeemed(
        address indexed _vault,
        address indexed _asset,
        address _sponsor,
        uint256 _amount
    );

    /* ----------------------------- admin interface ---------------------------- */
    function createVault(address _owner, bytes20 _salt) external authorised {
        bytes memory data = getEncodedVaultInitData(_owner);
        bytes32 newsalt = newSalt(_salt, _owner);
        address vaultBeaconProxy;
        bytes memory initCode = abi.encodePacked(
            type(BeaconProxy).creationCode,
            abi.encode(vaultBeacon(), data)
        );
        assembly {
            vaultBeaconProxy := create2(
                0,
                add(initCode, 0x20),
                mload(initCode),
                newsalt
            )
        }
        if (vaultBeaconProxy == address(0)) {
            revert FailedDeployVault();
        }
        diamondCut(vaultBeaconProxy);
        uint256 numVaults = LibVault.recordVault(_owner, vaultBeaconProxy);
        bytes4[] memory sigs = new bytes4[](6);
        sigs[0] = VaultAssetFacet(address(0)).withdrawRewards.selector;
        sigs[1] = VaultAssetFacet(address(0)).withdrawNFT.selector;
        sigs[2] = VaultManageFacet(address(0)).createSubvault.selector;
        sigs[3] = VaultManageFacet(address(0)).updateSubvaultOwner.selector;
        sigs[4] = VaultManageFacet(address(0)).pauseSubvault.selector;
        sigs[5] = VaultManageFacet(address(0)).unpauseSubvault.selector;
        LibSecurity.grantPermissions(
            LibAppStorage.ds().auth,
            _owner,
            vaultBeaconProxy,
            sigs
        );
        sigs = new bytes4[](2);
        sigs[0] = VaultAssetFacet(address(0)).grantLienOnAsset.selector;
        sigs[1] = VaultExternalFacet(address(0)).exec.selector;
        LibSecurity.grantPermissions(
            LibAppStorage.ds().auth,
            address(this),
            vaultBeaconProxy,
            sigs
        );
        emit VaultCreated(vaultBeaconProxy, _owner, numVaults);
    }

    /* ---------------------- vault configuration interface --------------------- */

    function setVaultBeacon(address _impl) external authorised {
        LibVault.setVaultBeacon(_impl);
    }

    /************************************** View Functions **************************************/
    function computeCounterfactualAddress(address _owner, bytes20 _salt)
        external
        view
        returns (address)
    {
        bytes memory data = getEncodedVaultInitData(_owner);
        bytes memory initCode = abi.encodePacked(
            type(BeaconProxy).creationCode,
            abi.encode(vaultBeacon(), data)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                newSalt(_salt, _owner),
                keccak256(initCode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function collectionInitialized(address _collection)
        external
        view
        returns (bool)
    {
        return LibAppStorage.ds()._reserveData[_collection].initialized;
    }

    function newSalt(bytes20 _salt, address _owner)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(keccak256(abi.encodePacked(_owner)), _salt)
            );
    }

    function vaultBeacon() public view returns (address) {
        return LibVault.vaultBeacon();
    }

    function subVaultBeacon() public view returns (address) {
        return LibVault.subVaultBeacon();
    }

    function getVaultAddr(address _user) external view returns (address) {
        return LibVault.getVaultAddress(_user);
    }

    function getEncodedVaultInitData(address _owner)
        internal
        view
        returns (bytes memory)
    {
        DiamondFacet memory cutFacet = LibVault.getDiamondFacets();
        bytes memory data = abi.encodeWithSelector(
            IVault(address(0)).initialize.selector,
            address(this),
            _owner,
            cutFacet.diamondCutFacet,
            cutFacet.diamondLoupeFacet,
            cutFacet.ownershipFacet
        );
        return data;
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidVaultCall();
error FailedDeployVault();
error IllegalVaultMarginParameters();

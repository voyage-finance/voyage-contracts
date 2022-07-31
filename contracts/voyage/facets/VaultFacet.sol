// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {LibAppStorage, AppStorage, Storage, VaultConfig, NFTInfo, DiamondFacet, ReserveConfigurationMap} from "../libraries/LibAppStorage.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibSecurity} from "../libraries/LibSecurity.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {IVault} from "../../vault/interfaces/IVault.sol";
import {IExternalAdapter} from "../interfaces/IExternalAdapter.sol";
import {IDiamondVersionFacet, Snapshot} from "../interfaces/IDiamondVersionFacet.sol";
import {Vault} from "../../vault/Vault.sol";
import {MarginEscrow} from "../../vault/escrow/MarginEscrow.sol";
import {VaultMarginFacet} from "../../vault/facets/VaultMarginFacet.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";
import {DiamondVersionFacet} from "./DiamondVersionFacet.sol";
import {VaultAssetFacet} from "../../vault/facets/VaultAssetFacet.sol";
import {VaultManageFacet} from "../../vault/facets/VaultManageFacet.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract VaultFacet is Storage, ReentrancyGuard {
    using LibReserveConfiguration for ReserveConfigurationMap;
    /* --------------------------------- events --------------------------------- */
    event VaultCreated(address _vault, address _owner, uint256 _numVaults);
    event VaultCreditLineInitialized(
        address indexed _vault,
        address indexed _asset,
        address _me,
        address _ce
    );
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
    event VaultMarginParametersUpdated(
        address indexed _collection,
        address indexed _vault,
        uint256 _min,
        uint256 _max,
        uint256 _marginRequirement
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
        emit VaultCreated(vaultBeaconProxy, _owner, numVaults);
    }

    function initCreditLine(
        address _vault,
        address _asset,
        address _collection
    ) external authorised returns (address, address) {
        (address _me, address _ce) = LibVault.initCreditLine(
            _vault,
            _asset,
            _collection
        );
        emit VaultCreditLineInitialized(_vault, _asset, _me, _ce);
        return (_me, _ce);
    }

    /* ----------------------------- user interface ----------------------------- */
    /**
     * @param _vault vault admin address
     * @param _collection collection address
     * @param _amount amount user is willing to deposit
     */
    function depositMargin(
        address _vault,
        address _collection,
        uint256 _amount
    ) external {
        (bool success, bytes memory ret) = _vault.call(
            abi.encodeWithSignature(
                "depositMargin(address,address,uint256)",
                _msgSender(),
                _collection,
                _amount
            )
        );
        if (!success) {
            revert InvalidVaultCall();
        }
        emit VaultMarginCredited(_vault, _collection, msg.sender, _amount);
    }

    /**
     * @dev  Delegate call to Vault's redeemSecurity
     * @param _vault vault address
     * @param _reserve reserve address
     * @param _amount redeem amount
     **/
    function redeemMargin(
        address payable _vault,
        address _reserve,
        uint256 _amount
    ) external {
        (bool success, bytes memory ret) = _vault.call(
            abi.encodeWithSignature(
                "redeemMargin(address,address,uint256)",
                _msgSender(),
                _reserve,
                _amount
            )
        );
        if (!success) {
            revert InvalidVaultCall();
        }
        emit VaultMarginRedeemed(_vault, _reserve, msg.sender, _amount);
    }

    /* ---------------------- vault configuration interface --------------------- */
    function setNFTInfo(
        address _erc721,
        address _erc20,
        address _marketplace
    ) external authorised {
        LibVault.setNFTInfo(_erc721, _erc20, _marketplace);
    }

    function setVaultBeacon(address _impl) external authorised {
        LibVault.setVaultBeacon(_impl);
    }

    /// @dev overrides global reserve margin parameters. use with extreme caution.
    /// @param _collection address of the underlying nft address
    /// @param _vault address of the vault
    /// @param _min min margin in whole tokens
    /// @param _max max margin in whole tokens
    /// @param _marginRequirement margin requirement
    function overrideMarginConfig(
        address _collection,
        address _vault,
        uint256 _min,
        uint256 _max,
        uint256 _marginRequirement
    ) external authorised {
        if (
            !LibReserveConfiguration.validateMarginParams(
                _min,
                _max,
                _marginRequirement
            )
        ) {
            revert IllegalVaultMarginParameters();
        }

        LibVault.setVaultConfig(
            _collection,
            _vault,
            _min,
            _max,
            _marginRequirement
        );

        emit VaultMarginParametersUpdated(
            _collection,
            _vault,
            _min,
            _max,
            _marginRequirement
        );
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

    function marginEscrowBeacon() public view returns (address) {
        return LibVault.marginEscrowBeacon();
    }

    function creditEscrowBeacon() public view returns (address) {
        return LibVault.creditEscrowBeacon();
    }

    function subVaultBeacon() public view returns (address) {
        return LibVault.subVaultBeacon();
    }

    function getCollectionInfo(address _collection, uint256 _tokenId)
        external
        view
        returns (NFTInfo memory)
    {
        return LibVault.getCollectionInfo(_collection, _tokenId);
    }

    function getVaultAddr(address _user) external view returns (address) {
        return LibVault.getVaultAddress(_user);
    }

    function getVaultEscrowAddr(address _user, address _asset)
        external
        view
        returns (address, address)
    {
        return LibVault.getVaultEscrowAddress(_user, _asset);
    }

    function getTokenAddrByMarketPlace(address _marketplace)
        external
        view
        returns (address)
    {
        return LibVault.getTokenAddrByMarketPlace(_marketplace);
    }

    function getMarketPlaceByAsset(address _asset)
        external
        view
        returns (address)
    {
        return LibVault.getMarketPlaceByAsset(_asset);
    }

    /**
     * @dev Get available credit
     * @param _vault user address
     * @param _collection collection address
     **/
    function getAvailableCredit(address _vault, address _collection)
        external
        view
        returns (uint256)
    {
        return LibVault.getAvailableCredit(_vault, _collection);
    }

    /**
     * @dev Get credit limit for a specific reserve
     * @param _vault vault address
     * @return _collection collection address
     **/
    function getCreditLimit(address _vault, address _collection)
        public
        view
        returns (uint256)
    {
        return LibVault.getCreditLimit(_vault, _collection);
    }

    function getMargin(address _vault, address _reserve)
        external
        view
        returns (uint256)
    {
        return LibVault.getMargin(_vault, _reserve);
    }

    function getVaultConfig(address _collection, address _vault)
        external
        view
        returns (VaultConfig memory)
    {
        return LibVault.getVaultConfig(_collection, _vault);
    }

    function getWithdrawableMargin(
        address _vault,
        address _reserve,
        address _user
    ) public view returns (uint256) {
        return LibVault.getWithdrawableMargin(_vault, _reserve, _user);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {LibAppStorage, AppStorage, Storage, NFTInfo, DiamondFacet, ReserveConfigurationMap} from "../libraries/LibAppStorage.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibSecurity} from "../libraries/LibSecurity.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {IVaultFacet} from "../interfaces/IVaultFacet.sol";
import {IVault} from "../../vault/Vault.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";
import {IWETH9} from "../../shared/interfaces/IWETH9.sol";

contract VaultFacet is Storage, ReentrancyGuard, IVaultFacet {
    using SafeERC20 for IERC20;
    using LibReserveConfiguration for ReserveConfigurationMap;

    /* ----------------------------- admin interface ---------------------------- */
    function createVault(
        address _user,
        bytes20 _salt,
        uint256 _gasUnits,
        uint256 _gasPrice
    ) external authorised {
        bytes memory data = getEncodedVaultInitData(_user);
        bytes32 newsalt = newSalt(_salt, _user);
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
        address treasury = LibAppStorage.ds().protocolFee.treasuryAddress;
        if (treasury == address(0)) {
            revert InvalidTreasuryAddress();
        }
        uint256 refundAmount = _gasUnits * _gasPrice;
        IVault(vaultBeaconProxy).execute("", treasury, refundAmount);
        uint256 numVaults = LibVault.recordVault(_user, vaultBeaconProxy);
        emit VaultCreated(vaultBeaconProxy, _user, numVaults, refundAmount);
    }

    /* ---------------------- vault configuration interface --------------------- */
    function getVaultImpl() external view returns (address) {
        return LibVault.getVaultImpl();
    }

    function setVaultImpl(address _impl) external authorised {
        if (_impl == address(0) || !Address.isContract(_impl)) {
            revert InvalidVaultImpl();
        }
        LibVault.setVaultImpl(_impl);
        emit VaultImplementationUpdated(_impl);
    }

    /* ---------------------- user interface --------------------- */
    function withdrawNFT(
        address _vault,
        address _collection,
        uint256 _tokenId
    ) external onlyVaultOwner(_vault, _msgSender()) whenNotPaused nonReentrant {
        checkContractAddr(_collection);
        if (LibAppStorage.ds().nftIndex[_collection][_tokenId].isCollateral) {
            revert InvalidWithdrawal();
        }
        delete LibAppStorage.ds().nftIndex[_collection][_tokenId];
        bytes4 selector = IERC721(_collection).transferFrom.selector;
        bytes memory param = abi.encode(_vault, _msgSender(), _tokenId);
        bytes memory data = abi.encodePacked(selector, param);
        IVault(_vault).execute(data, _collection, 0);
    }

    function transferCurrency(
        address _vault,
        address _currency,
        address _to,
        uint256 _amount
    ) external onlyVaultOwner(_vault, _msgSender()) nonReentrant {
        checkContractAddr(_currency);
        // to prevent currency being a collection address
        if (LibAppStorage.ds()._reserveData[_currency].currency != address(0)) {
            revert InvalidCurrencyAddress();
        }
        bytes4 selector = IERC20(_currency).transferFrom.selector;
        bytes memory param = abi.encode(_vault, _to, _amount);
        bytes memory data = abi.encodePacked(selector, param);
        IVault(_vault).execute(data, _currency, 0);
    }

    function wrapVaultETH(address _vault, uint256 _value)
        external
        onlyVaultOwner(_vault, _msgSender())
        whenNotPaused
        nonReentrant
    {
        bytes4 selector = IWETH9(address(0)).deposit.selector;
        bytes memory data = abi.encodePacked(selector);
        IVault(_vault).execute(data, address(LibAppStorage.ds().WETH9), _value);
    }

    function unwrapVaultETH(address _vault, uint256 _vaule)
        external
        onlyVaultOwner(_vault, _msgSender())
        whenNotPaused
        nonReentrant
    {
        bytes4 selector = IWETH9(address(0)).withdraw.selector;
        bytes memory param = abi.encode(_vaule);
        bytes memory data = abi.encodePacked(selector, param);
        IVault(_vault).execute(data, address(LibAppStorage.ds().WETH9), 0);
    }

    function approveMarketplace(
        address _vault,
        address _marketplace,
        bool revoke
    ) external onlyVaultOwner(_vault, _msgSender()) whenNotPaused nonReentrant {
        address adapterAddr = LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr;
        if (adapterAddr == address(0)) {
            revert InvalidMarketplace();
        }
        bytes4 selector = IERC20(address(0)).approve.selector;
        bytes memory param = abi.encode(
            _marketplace,
            revoke ? 0 : type(uint256).max
        );
        bytes memory data = abi.encodePacked(selector, param);
        address currency = address(LibAppStorage.ds().WETH9);
        IVault(_vault).execute(data, currency, 0);
    }

    /* ---------------------- view functions --------------------- */
    function computeCounterfactualAddress(address _user, bytes20 _salt)
        external
        view
        returns (address)
    {
        bytes memory data = getEncodedVaultInitData(_user);
        bytes memory initCode = abi.encodePacked(
            type(BeaconProxy).creationCode,
            abi.encode(vaultBeacon(), data)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                newSalt(_salt, _user),
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

    function subVaultBeacon() external view returns (address) {
        return LibVault.subVaultBeacon();
    }

    function getVaultAddr(address _user) external view returns (address) {
        return LibVault.getVaultAddress(_user);
    }

    function getEncodedVaultInitData(address _user)
        internal
        view
        returns (bytes memory)
    {
        bytes memory data = abi.encodeWithSelector(
            IVault(address(0)).initialize.selector,
            address(this),
            _user,
            LibAppStorage.ds().WETH9
        );
        return data;
    }

    function checkContractAddr(address _collection) internal view {
        if (!Address.isContract(_collection)) {
            revert InvalidCollectionAddress();
        }
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidVaultImpl();
error InvalidCollectionAddress();
error InvalidCurrencyAddress();
error FailedDeployVault();
error InvalidWithdrawal();
error InvalidMarketplace();
error InvalidTreasuryAddress();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {LibAppStorage, AppStorage, Storage, NFTInfo, DiamondFacet, ReserveConfigurationMap} from "../libraries/LibAppStorage.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibSecurity} from "../libraries/LibSecurity.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {IVault} from "../../vault/Vault.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";

contract VaultFacet is Storage, ReentrancyGuard {
    using SafeERC20 for IERC20;
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
    function createVault(address _user, bytes20 _salt) external authorised {
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
        uint256 numVaults = LibVault.recordVault(_user, vaultBeaconProxy);
        emit VaultCreated(vaultBeaconProxy, _user, numVaults);
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
    }

    /* ---------------------- user interface --------------------- */
    function withdrawNFT(
        address _vault,
        address _collection,
        uint256 _tokenId
    ) external nonReentrant {
        checkVaultAddr(_vault);
        checkContractAddr(_collection);
        if (LibAppStorage.ds().nftIndex[_collection][_tokenId].isCollateral) {
            revert InvalidWithdrawal();
        }
        delete LibAppStorage.ds().nftIndex[_collection][_tokenId];
        bytes4 selector = IERC721(_collection).transferFrom.selector;
        bytes memory param = abi.encode(_vault, _msgSender(), _tokenId);
        bytes memory data = abi.encodePacked(selector, param);
        bytes memory encodedData = abi.encode(_collection, data);
        IVault(_vault).execute(encodedData, 0);
    }

    function transferCurrency(
        address _vault,
        address _currency,
        address _to,
        uint256 _amount
    ) external nonReentrant {
        checkVaultAddr(_vault);
        checkContractAddr(_currency);
        // to prevent currency being a collection address
        if (LibAppStorage.ds()._reserveData[_currency].currency != address(0)) {
            revert InvalidCurrencyAddress();
        }
        bytes4 selector = IERC20(_currency).transferFrom.selector;
        bytes memory param = abi.encode(_vault, _to, _amount);
        bytes memory data = abi.encodePacked(selector, param);
        bytes memory encodedData = abi.encode(_currency, data);
        IVault(_vault).execute(encodedData, 0);
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

    function subVaultBeacon() public view returns (address) {
        return LibVault.subVaultBeacon();
    }

    function getVaultAddr(address _user) public view returns (address) {
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
            LibAppStorage.ds().paymaster,
            LibAppStorage.ds().WETH9
        );
        return data;
    }

    function checkVaultAddr(address _vault) internal view {
        if (!Address.isContract(_vault)) {
            revert InvalidVaultAddress();
        }
        if (LibVault.getVaultAddress(_msgSender()) != _vault) {
            revert InvalidVaultCall();
        }
    }

    function checkContractAddr(address _collection) internal view {
        if (!Address.isContract(_collection)) {
            revert InvalidCollectionAddress();
        }
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidVaultImpl();
error InvalidVaultCall();
error InvalidVaultAddress();
error InvalidCollectionAddress();
error InvalidCurrencyAddress();
error FailedDeployVault();
error InvalidWithdrawal();

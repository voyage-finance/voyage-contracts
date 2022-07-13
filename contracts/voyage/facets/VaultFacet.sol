// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {LibAppStorage, AppStorage, Storage, VaultConfig, NFTInfo, DiamondFacet} from "../libraries/LibAppStorage.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {IVault} from "../../vault/interfaces/IVault.sol";
import {IExternalAdapter} from "../interfaces/IExternalAdapter.sol";
import {IDiamondVersionFacet, Snapshot} from "../interfaces/IDiamondVersionFacet.sol";
import {Vault} from "../../vault/Vault.sol";
import {MarginEscrow} from "../../vault/escrow/MarginEscrow.sol";
import {VaultMarginFacet} from "../../vault/facets/VaultMarginFacet.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";
import {DiamondVersionFacet} from "./DiamondVersionFacet.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract VaultFacet is Storage, ReentrancyGuard {
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

    /* ----------------------------- admin interface ---------------------------- */
    function createVault(address owner) external authorised {
        DiamondFacet memory cutFacet = LibVault.getDiamondFacets();
        bytes memory data = abi.encodeWithSelector(
            IVault(address(0)).initialize.selector,
            address(this),
            owner,
            cutFacet.diamondCutFacet,
            cutFacet.diamondLoupeFacet,
            cutFacet.ownershipFacet
        );
        BeaconProxy vaultBeaconProxy = new BeaconProxy(
            address(vaultBeacon()),
            data
        );
        if (address(vaultBeaconProxy) == address(0)) {
            revert FailedDeployVault();
        }
        diamondCut(address(vaultBeaconProxy));
        uint256 numVaults = LibVault.recordVault(
            owner,
            address(vaultBeaconProxy)
        );
        emit VaultCreated(address(vaultBeaconProxy), owner, numVaults);
    }

    function initCreditLine(address _vault, address _asset)
        external
        authorised
        returns (address, address)
    {
        (address _me, address _ce) = LibVault.initCreditLine(_vault, _asset);
        emit VaultCreditLineInitialized(_vault, _asset, _me, _ce);
        return (_me, _ce);
    }

    /* ----------------------------- user interface ----------------------------- */
    /**
     * @param _vault vault admin address
     * @param _reserve reserve address
     * @param _amount amount user is willing to deposit
     */
    function depositMargin(
        address _vault,
        address _reserve,
        uint256 _amount
    ) external {
        (bool success, bytes memory ret) = _vault.call(
            abi.encodeWithSignature(
                "depositMargin(address,address,uint256)",
                _msgSender(),
                _reserve,
                _amount
            )
        );
        if (!success) {
            revert InvalidVaultCall();
        }
        emit VaultMarginCredited(_vault, _reserve, msg.sender, _amount);
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

    /**
     * @dev Set max margin for _reserve
     * @param _reserve reserve address
     * @param _amount max amount sponsor can deposit
     */
    function setMaxMargin(address _reserve, uint256 _amount)
        external
        authorised
    {
        LibVault.setMaxMargin(_reserve, _amount);
    }

    /**
     * @dev Set min margin for _reserve
     * @param _reserve reserve address
     * @param _amount min amount sponsor can deposit
     */
    function setMinMargin(address _reserve, uint256 _amount)
        external
        authorised
    {
        LibVault.setMinMargin(_reserve, _amount);
    }

    /**
     * @dev Update the margin requirement
     * @param _reserve reserve address
     * @param _requirement expressed in Ray
     */
    function setMarginRequirement(address _reserve, uint256 _requirement)
        external
        authorised
    {
        LibVault.setMarginRequirement(_reserve, _requirement);
    }

    function setVaultBeacon(address _impl) external authorised {
        LibVault.setVaultBeacon(_impl);
    }

    /************************************** View Functions **************************************/
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

    function getNFTInfo(address _erc721Addr, uint256 _tokenId)
        external
        view
        returns (NFTInfo memory)
    {
        return LibVault.getNFTInfo(_erc721Addr, _tokenId);
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
     * @param _reserve reserve address
     **/
    function getAvailableCredit(address _vault, address _reserve)
        external
        view
        returns (uint256)
    {
        return LibVault.getAvailableCredit(_vault, _reserve);
    }

    /**
     * @dev Get credit limit for a specific reserve
     * @param _vault vault address
     * @return _reserve reserve address
     **/
    function getCreditLimit(address _vault, address _reserve)
        public
        view
        returns (uint256)
    {
        return LibVault.getCreditLimit(_vault, _reserve);
    }

    function getMargin(address _vault, address _reserve)
        external
        view
        returns (uint256)
    {
        return LibVault.getMargin(_vault, _reserve);
    }

    function getWithdrawableMargin(
        address _vault,
        address _reserve,
        address _user
    ) public view returns (uint256) {
        return LibVault.getWithdrawableMargin(_vault, _reserve, _user);
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidVaultCall();
error FailedDeployVault();

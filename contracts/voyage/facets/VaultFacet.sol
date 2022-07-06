// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {LibAppStorage, AppStorage, Storage, VaultConfig, NFTInfo} from "../libraries/LibAppStorage.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {IExternalAdapter} from "../interfaces/IExternalAdapter.sol";
import {IDiamondVersionFacet, Snapshot} from "../interfaces/IDiamondVersionFacet.sol";
import {Vault} from "../../vault/Vault.sol";
import {MarginEscrow} from "../../vault/escrow/MarginEscrow.sol";
import {VaultMarginFacet} from "../../vault/facets/VaultMarginFacet.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";
import {DiamondVersionFacet} from "./DiamondVersionFacet.sol";
import "hardhat/console.sol";

contract VaultFacet is Storage, ReentrancyGuard {
    /* --------------------------------- events --------------------------------- */
    event VaultCreated(address _vault, address _owner, uint256 _numVaults);
    event VaultAssetInitialized(
        address indexed _vault,
        address indexed _asset,
        address _escrow
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
    function createVault(address owner, bytes32 salt) external authorised {
        address deployedVault = clone(owner, salt);
        console.log("VaultFacet#createVault, deployed vault: ", deployedVault);
        uint256 numVaults = LibVault.recordVault(owner, deployedVault);
        emit VaultCreated(deployedVault, owner, numVaults);
    }

    function clone(address _owner, bytes32 salt) internal returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 currentVersion = s.currentVersion;
        Snapshot memory snapshot = s.snapshotMap[currentVersion];
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](
            snapshot.facets.length
        );
        for (uint256 i = 0; i < snapshot.facets.length; i++) {
            address facetAddr = snapshot.facets[i].facetAddress;
            bytes4[] memory selectors = snapshot.facets[i].functionSelectors;
            facetCuts[i].facetAddress = facetAddr;
            facetCuts[i].functionSelectors = selectors;
            facetCuts[i].action = IDiamondCut.FacetCutAction.Add;
        }
        address vault = LibAppStorage.diamondStorage().vaultFactory.createVault(
            _owner,
            address(this),
            salt
        );
        DiamondCutFacet(vault).diamondCut(
            facetCuts,
            snapshot.init,
            snapshot.initArgs
        );
        return vault;
    }

    function initAsset(address _vault, address _asset)
        external
        authorised
        returns (address)
    {
        address escrow = LibVault.initVaultAsset(_vault, _asset);
        emit VaultAssetInitialized(_vault, _asset, escrow);
        return escrow;
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
        require(success, "VaultFacet#depositMargin: call error");
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
        require(success, "VaultFacet#redeemMargin: call error");

        emit VaultMarginRedeemed(_vault, _reserve, msg.sender, _amount);
    }

    /* ---------------------- vault configuration interface --------------------- */
    function setVaultStrategyAddr(address _target, address _strategyAddr)
        external
        authorised
    {
        LibVault.setVaultStrategyAddr(_target, _strategyAddr);
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

    function updateNFTPrice(
        address _erc721Addr,
        uint256 _cardId,
        uint256 _cardPrice
    ) external {
        // todo check auth
        LibVault.updateNFTPrice(_erc721Addr, _cardId, _cardPrice);
    }

    function validate(
        address _target,
        bytes4 _selector,
        bytes calldata _payload
    )
        external
        view
        returns (
            address[] memory,
            bytes[] memory,
            address[] memory,
            bytes[] memory
        )
    {
        return LibVault.validate(_target, _selector, _payload);
    }

    /************************************** View Functions **************************************/
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

    function getERC721Addr(address _target) external returns (address) {
        return LibVault.getERC721Addr(_target);
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

    function getAdapter(address _target) external view returns (address) {
        return LibVault.getAdapter(_target);
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

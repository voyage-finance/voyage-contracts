// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MarginEscrow} from "../../component/vault/MarginEscrow.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IExternalAdapter} from "../../interfaces/IExternalAdapter.sol";
import {LibAppStorage, Storage, VaultConfig, NFTInfo} from "../../libraries/LibAppStorage.sol";
import {LibVault} from "../../libraries/LibVault.sol";

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
    function createVault(address owner) external authorised returns (address) {
        address vault;
        uint256 numVaults;
        (vault, numVaults) = LibVault.deployVault(address(this), owner);
        emit VaultCreated(vault, owner, numVaults);
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
        IVault(_vault).depositMargin(_msgSender(), _reserve, _amount);
        emit VaultMarginCredited(_vault, _reserve, msg.sender, _amount);
    }

    /**
     * @dev  Delegate call to Vault's redeemSecurity
     * @param _vault vault address
     * @param _reserve reserve address
     * @param _amount redeem amount
     **/
    function redeemMargin(
        address _vault,
        address _reserve,
        uint256 _amount
    ) external {
        IVault(_vault).redeemMargin(payable(_msgSender()), _reserve, _amount);
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

    /**
     * @dev Update the vault impl address
     * @param _impl vault impl contract
     */
    function updateVaultImplContract(address _impl) external authorised {
        LibVault.updateVaultImplContract(_impl);
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

    function getVaultConfig(address _reserve)
        external
        view
        returns (VaultConfig memory)
    {
        return LibVault.getVaultConfig(_reserve);
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

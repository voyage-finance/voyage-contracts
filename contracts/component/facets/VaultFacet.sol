// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MarginEscrow} from "../../component/vault/MarginEscrow.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IExternalAdapter} from "../../interfaces/IExternalAdapter.sol";
import {LibAppStorage, Storage, VaultConfig, Authorisation} from "../../libraries/LibAppStorage.sol";
import {LibVault} from "../../libraries/LibVault.sol";
import {LibSecurity} from "../../libraries/LibSecurity.sol";

contract VaultFacet is Storage, ReentrancyGuard {
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using LibSecurity for Authorisation;

    /* --------------------------------- events --------------------------------- */
    event VaultCreated(address _vault, address _owner, uint256 _numVaults);
    event VaultInitialized(address _vault, address _reserve);
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
    function createVault(address owner, address _reserve)
        external
        authorised
        returns (address)
    {
        address vault;
        uint256 numVaults;
        (vault, numVaults) = LibVault.deployVault(
            address(this),
            owner,
            _reserve
        );
        emit VaultCreated(vault, owner, numVaults);
        return vault;
    }

    function initAsset(address _vault, address _asset)
        external
        authorised
        returns (address)
    {
        return LibVault.initVaultAsset(_vault, _asset);
    }

    /* ----------------------------- user interface ----------------------------- */
    /**
     * @param _owner vault admin address
     * @param _reserve reserve address
     * @param _amount amount user is willing to deposit
     */
    function depositMargin(
        address _owner,
        address _reserve,
        uint256 _amount
    ) external {
        address vaultAddress = LibVault.getVaultAddress(_owner);
        IVault(vaultAddress).depositMargin(msg.sender, _reserve, _amount);
        emit VaultMarginCredited(vaultAddress, _reserve, msg.sender, _amount);
    }

    /**
     * @dev  Delegate call to Vault's redeemSecurity
     * @param _owner user address
     * @param _reserve reserve address
     * @param _amount redeem amount
     **/
    function redeemMargin(
        address _owner,
        address _reserve,
        uint256 _amount
    ) external {
        address vaultAddress = LibVault.getVaultAddress(_owner);
        IVault(vaultAddress).redeemMargin(
            payable(msg.sender),
            _reserve,
            _amount
        );
        emit VaultMarginRedeemed(vaultAddress, _reserve, msg.sender, _amount);
    }

    /************************ HouseKeeping Function ******************************/

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

    function setVaultStrategyAddr(address _target, address _strategyAddr)
        external
        authorised
    {
        LibVault.setVaultStrategyAddr(_target, _strategyAddr);
    }

    function updateNFTPrice(
        address _erc721Addr,
        uint256 _cardId,
        uint256 _cardPrice
    ) external {
        // todo check auth
        LibVault.updateNFTPrice(_erc721Addr, _cardId, _cardPrice);
    }

    /**
     * @dev Update the vault impl address
     * @param _impl vault impl contract
     */
    function updateVaultImplContract(address _impl) external authorised {
        LibVault.updateVaultImplContract(_impl);
    }

    function validate(
        address _target,
        bytes4 _selector,
        bytes calldata _payload
    ) external returns (address, bytes memory) {
        return LibVault.validate(_target, _selector, _payload);
    }

    /************************************** View Functions **************************************/

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

    /**
     * @dev Get available credit
     * @param _user user address
     * @param _reserve reserve address
     **/
    function getAvailableCredit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return LibVault.getAvailableCredit(_user, _reserve);
    }

    /**
     * @dev Get credit limit for a specific reserve
     * @param _user user address
     * @return _reserve reserve address
     **/
    function getCreditLimit(address _user, address _reserve)
        public
        view
        returns (uint256)
    {
        return LibVault.getCreditLimit(_user, _reserve);
    }

    function getMargin(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return LibVault.getMargin(_user, _reserve);
    }

    function getVault(address _owner) external view returns (address) {
        return LibVault.getVaultAddress(_owner);
    }

    function getAllVaults() external view returns (address[] memory) {
        return s.vaults;
    }

    function getWithdrawableMargin(
        address _vault,
        address _reserve,
        address _user
    ) public view returns (uint256) {
        return LibVault.getWithdrawableMargin(_vault, _reserve, _user);
    }

    function getTotalWithdrawableMargin(address _vault, address _reserve)
        public
        view
        returns (uint256)
    {
        return LibVault.getTotalWithdrawableMargin(_vault, _reserve);
    }
}

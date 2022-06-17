// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SecurityDepositEscrow} from "../../component/vault/SecurityDepositEscrow.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {LibAppStorage, Storage, VaultConfig} from "../../libraries/LibAppStorage.sol";
import {LibVault} from "../../libraries/LibVault.sol";

contract VaultFacet is Storage, ReentrancyGuard {
    using WadRayMath for uint256;
    using SafeMath for uint256;

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
    function createVault(bytes32 _salt) external onlyAdmin returns (address) {
        address vault;
        uint256 numVaults;
        (vault, numVaults) = LibVault.deployVault(_msgSender(), _salt);
        emit VaultCreated(vault, _msgSender(), numVaults);
        return vault;
    }

    /// @notice Initializes a vault for a specific underlying asset and creates a margin escrow
    /// @param _vault The address of the vault to initialise
    /// @param _reserve The address of the underlying asset. Must be ERC20.
    function initVault(address _vault, address _reserve) external onlyAdmin {
        LibVault.initVault(_vault, _reserve);
    }

    /* ----------------------------- user interface ----------------------------- */
    /**
     * @param _sponsor deposits the reserve into the amount
     * @param _owner vault admin address
     * @param _reserve reserve address
     * @param _amount amount user is willing to deposit
     */
    function depositMargin(
        address _sponsor,
        address _owner,
        address _reserve,
        uint256 _amount
    ) external {
        address vaultAddress = LibVault.getVaultAddress(_owner);
        IVault(vaultAddress).depositSecurity(_sponsor, _reserve, _amount);
        emit VaultMarginCredited(vaultAddress, _reserve, _sponsor, _amount);
    }

    /**
     * @dev  Delegate call to Vault's redeemSecurity
     * @param _sponsor sponsor address
     * @param _owner user address
     * @param _reserve reserve address
     * @param _amount redeem amount
     **/
    function redeemMargin(
        address payable _sponsor,
        address _owner,
        address _reserve,
        uint256 _amount
    ) external {
        address vaultAddress = LibVault.getVaultAddress(_owner);
        IVault(vaultAddress).redeemSecurity(_sponsor, _reserve, _amount);
        emit VaultMarginRedeemed(vaultAddress, _reserve, _sponsor, _amount);
    }

    /************************ HouseKeeping Function ******************************/

    /**
     * @dev Set max security deposit for _reserve
     * @param _reserve reserve address
     * @param _amount max amount sponsor can deposit
     */
    function setMaxSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyAdmin
    {
        LibVault.setMaxSecurityDeposit(_reserve, _amount);
    }

    /**
     * @dev Set min security deposit for _reserve
     * @param _reserve reserve address
     * @param _amount min amount sponsor can deposit
     */
    function setMinSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyAdmin
    {
        LibVault.setMinSecurityDeposit(_reserve, _amount);
    }

    /**
     * @dev Update the security deposit requirement
     * @param _reserve reserve address
     * @param _requirement expressed in Ray
     */
    function setSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) external onlyAdmin {
        LibVault.setSecurityDepositRequirement(_reserve, _requirement);
    }

    /************************************** View Functions **************************************/

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

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return LibVault.getSecurityDeposit(_user, _reserve);
    }

    function getSecurityDepositTokenAddress(address vault)
        private
        view
        returns (address)
    {
        return LibVault.getSecurityDepositTokenAddress(vault);
    }

    function getVault(address _owner) external view returns (address) {
        return LibVault.getVaultAddress(_owner);
    }

    function getAllVaults() external view returns (address[] memory) {
        return s.vaults;
    }

    function getWithdrawableDeposit(
        address _owner,
        address _reserve,
        address _sponsor
    ) public view returns (uint256) {
        return LibVault.getWithdrawableDeposit(_owner, _reserve, _sponsor);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SecurityDepositEscrow} from "../../component/vault/SecurityDepositEscrow.sol";
import {Proxyable} from "../../libraries/proxy/Proxyable.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {IVaultManager} from "../../interfaces/IVaultManager.sol";
import {IAddressResolver} from "../../interfaces/IAddressResolver.sol";
import {IVaultFactory} from "../../interfaces/IVaultFactory.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {Voyager} from "../../component/Voyager.sol";
import {VaultStorage} from "./VaultStorage.sol";
import {VaultFactory} from "./VaultFactory.sol";
import {LibVault} from "../../libraries/LibVault.sol";

contract VaultManager is ReentrancyGuard, Proxyable, IVaultManager {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    IAddressResolver public addressResolver;
    address public vaultFactory;

    constructor(
        address payable _proxy,
        address _addressResolver,
        address payable _voyager,
        address _vaultFactory
    ) public Proxyable(_proxy) {
        addressResolver = IAddressResolver(_addressResolver);
        vaultFactory = _vaultFactory;
        voyager = Voyager(_voyager);
    }

    modifier onlyAdmin() {
        _requireCallerAdmin();
        _;
    }

    /************************************** User Functions **************************************/

    /**
     * @dev Create a Vault for user
     * @param _user the address of the player
     **/
    function createVault(
        address _user,
        address _reserve,
        bytes32 _salt
    ) external onlyProxy returns (address) {
        address vault = VaultFactory(vaultFactory).createVault(_salt);
        require(vault != address(0), "deploy vault failed");
        uint256 len = VaultStorage(getVaultStorageAddress()).pushNewVault(
            _user,
            vault
        );
        proxy._emit(
            abi.encode(vault, len),
            2,
            keccak256("VaultCreated(address, address, uint256)"),
            bytes32(abi.encodePacked(_user)),
            0,
            0
        );
        return vault;
    }

    function initVault(address _vault, address _reserve) external onlyProxy {
        SecurityDepositEscrow securityDepositEscrow = new SecurityDepositEscrow(
            _vault
        );
        IVault(_vault).initialize(
            addressResolver.getVoyage(),
            securityDepositEscrow
        );
        IVault(_vault).initSecurityDepositToken(_reserve);
    }

    /**
     * @dev Delegate call to Vault's depositSecurity
     * @param _sponsor who actual deposits the reserve into the amount
     * @param _vaultUser user address
     * @param _reserve reserve address
     * @param _amount amount user is willing to deposit
     */
    function depositSecurity(
        address _sponsor,
        address _vaultUser,
        address _reserve,
        uint256 _amount
    ) external onlyProxy {
        address vaultAddress = _getVault(_vaultUser);
        IVault(vaultAddress).depositSecurity(_sponsor, _reserve, _amount);
        _emit(
            _sponsor,
            _vaultUser,
            _reserve,
            _amount,
            keccak256("SecurityDeposited(address, address, address, uint256)")
        );
    }

    /**
     * @dev  Delegate call to Vault's redeemSecurity
     * @param _sponsor sponsor address
     * @param _vaultUser user address
     * @param _reserve reserve address
     * @param _amount redeem amount
     **/
    function redeemSecurity(
        address payable _sponsor,
        address _vaultUser,
        address _reserve,
        uint256 _amount
    ) external onlyProxy {
        address vaultAddress = _getVault(_vaultUser);
        IVault(vaultAddress).redeemSecurity(_sponsor, _reserve, _amount);
        proxy._emit(
            abi.encode(_vaultUser, _reserve, _amount),
            2,
            keccak256("SecurityRedeemed(address, address, address, uint256)"),
            bytes32(abi.encodePacked(_sponsor)),
            0,
            0
        );
    }

    /************************ HouseKeeping Function ******************************/

    /**
     * @dev Set max security deposit for _reserve
     * @param _reserve reserve address
     * @param _amount max amount sponsor can deposit
     */
    function setMaxSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyProxy
        onlyAdmin
    {
        VaultStorage(getVaultStorageAddress()).setMaxSecurityDeposit(
            _reserve,
            _amount
        );
    }

    /**
     * @dev Set min security deposit for _reserve
     * @param _reserve reserve address
     * @param _amount min amount sponsor can deposit
     */
    function setMinSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyProxy
        onlyAdmin
    {
        VaultStorage(getVaultStorageAddress()).setMinSecurityDeposit(
            _reserve,
            _amount
        );
    }

    /**
     * @dev Update the security deposit requirement
     * @param _reserve reserve address
     * @param _requirement expressed in Ray
     */
    function setSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) external onlyProxy onlyAdmin {
        VaultStorage(getVaultStorageAddress()).setSecurityDepositRequirement(
            _reserve,
            _requirement
        );
    }

    /************************************** View Functions **************************************/

    function getVaultConfig(address _reserve)
        external
        view
        onlyProxy
        returns (DataTypes.VaultConfig memory)
    {
        return VaultStorage(getVaultStorageAddress()).getVaultConfig(_reserve);
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
        uint256 creditLimit = getCreditLimit(_user, _reserve);
        uint256 principal;
        uint256 interest;
        address vault = _getVault(_user);
        LibVault.getVaultDebt(_reserve, vault);
        uint256 accumulatedDebt = principal.add(interest);
        if (creditLimit < accumulatedDebt) {
            return 0;
        }
        return creditLimit - accumulatedDebt;
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
        uint256 currentSecurityDeposit = _getSecurityDeposit(_user, _reserve);
        DataTypes.VaultConfig memory vc = VaultStorage(getVaultStorageAddress())
            .getVaultConfig(_reserve);
        uint256 securityDepositRequirement = vc.securityDepositRequirement;
        require(
            securityDepositRequirement != 0,
            "security deposit requirement cannot be 0"
        );
        uint256 creditLimitInRay = currentSecurityDeposit.wadToRay().rayDiv(
            securityDepositRequirement
        );
        return creditLimitInRay.rayToWad();
    }

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return _getSecurityDeposit(_user, _reserve);
    }

    function getVaultStorageAddress() private view returns (address) {
        return addressResolver.getVaultStorage();
    }

    function getSecurityDepositTokenAddress(address vault)
        private
        view
        returns (address)
    {
        return IVault(vault).getSecurityDepositTokenAddress();
    }

    /**
     * @dev Get existing Vault contract address for user
     * @param _user the address of the player
     * @return Vault address
     **/
    function getVault(address _user) external view returns (address) {
        return _getVault(_user);
    }

    function getAllVaults() external view returns (address[] memory) {
        return VaultStorage(getVaultStorageAddress()).getAllVaults();
    }

    function getWithdrawableDeposit(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) public view returns (uint256) {
        address vaultAddress = _getVault(_vaultUser);
        return IVault(vaultAddress).getWithdrawableDeposit(_sponsor, _reserve);
    }

    /************************************** Private Functions **************************************/

    function _getSecurityDeposit(address _user, address _reserve)
        internal
        view
        returns (uint256)
    {
        address vaultAddress = _getVault(_user);
        uint256 currentSecurityDeposit = IVault(vaultAddress)
            .getCurrentSecurityDeposit(_reserve);
        return currentSecurityDeposit;
    }

    function _getVault(address _user) internal view returns (address) {
        return VaultStorage(getVaultStorageAddress()).getVaultAddress(_user);
    }

    function _requireCallerAdmin() internal {
        IACLManager aclManager = IACLManager(
            addressResolver.getAddress("aclManager")
        );
        require(aclManager.isVaultManager(messageSender), "Not vault admin");
    }

    function _emit(
        address _sponsor,
        address _vaultUser,
        address _reserve,
        uint256 _amount,
        bytes32 _topic
    ) internal {
        proxy._emit(
            abi.encode(_vaultUser, _reserve, _amount),
            2,
            _topic,
            bytes32(abi.encodePacked(_sponsor)),
            0,
            0
        );
    }
}

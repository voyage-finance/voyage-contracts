// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../tokenization/SecurityDepositToken.sol';
import '../../mock/Tus.sol';
import '../../libraries/math/WadRayMath.sol';
import './Vault.sol';
import '../../interfaces/IVaultManager.sol';
import '../../interfaces/IACLManager.sol';
import '../Voyager.sol';
import '../infra/AddressResolver.sol';
import './VaultStorage.sol';

contract VaultManager is
    AccessControl,
    ReentrancyGuard,
    Proxyable,
    IVaultManager
{
    using SafeERC20 for ERC20;
    using WadRayMath for uint256;
    using SafeMath for uint256;

    address public voyager;
    mapping(address => uint256) public maxSecurityDeposit;
    // reserve address => requirement expressed in ray
    mapping(address => uint256) public securityDepositRequirement;

    constructor(address payable _proxy, address _voyager)
        public
        Proxyable(_proxy)
    {
        voyager = _voyager;
    }

    /************************************** User Functions **************************************/

    /**
     * @dev Create a Vault for user
     * @param _user the address of the player
     **/
    function createVault(address _user)
        external
        onlyProxy
        returns (address vault)
    {
        bytes memory bytecode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_user));
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        Vault(vault).initialize(voyager, _user);
        uint256 len = VaultStorage(getVaultStorageAddress()).pushNewVault(
            _user,
            vault
        );
        emit VaultCreated(_user, vault, len);
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
        Vault(vaultAddress).depositSecurity(_sponsor, _reserve, _amount);
        emit SecurityDeposited(_sponsor, _vaultUser, _reserve, _amount);
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
        Vault(vaultAddress).redeemSecurity(_sponsor, _reserve, _amount);
        emit SecurityRedeemed(_sponsor, _vaultUser, _reserve, _amount);
    }

    // placeholder function
    function slash(
        address _vaultUser,
        address _reserve,
        address payable _to,
        uint256 _amount
    ) public nonReentrant onlyProxy {
        address vaultAddress = _getVault(_vaultUser);
        return Vault(vaultAddress).slash(_reserve, _to, _amount);
    }

    /************************ HouseKeeping Function ******************************/

    function initSecurityDepositToken(address _vaultUser, address _reserve)
        external
        onlyProxy
    {
        address vaultAddress = _getVault(_vaultUser);
        Vault(vaultAddress).initSecurityDepositToken(_reserve);
    }

    /**
     * Init a deployed Vault, ensure it has overlying security deposit token and corresponding staking contract
     * _vaultUser the user/owner of this vault
     * _reserve the underlying asset address e.g. TUS
     **/
    function initStakingContract(address _vaultUser, address _reserve)
        external
        onlyProxy
    {
        address vaultAddress = _getVault(_vaultUser);
        Vault(vaultAddress).initStakingContract(_reserve);
    }

    function setMaxSecurityDeposit(
        address _reserve,
        uint256 _amount,
        address _caller
    ) external onlyProxy {
        _requireCallerAdmin(_caller);
        maxSecurityDeposit[_reserve] = _amount;
    }

    function removeMaxSecurityDeposit(address _reserve) external onlyProxy {
        delete maxSecurityDeposit[_reserve];
    }

    function updateSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) external onlyProxy {
        securityDepositRequirement[_reserve] = _requirement;
        emit SecurityDepositRequirementSet(_reserve, _requirement);
    }

    /************************************** View Functions **************************************/

    function removeSecurityDepositRequirement(address _reserve)
        external
        onlyProxy
    {
        delete securityDepositRequirement[_reserve];
    }

    function getSecurityDepositRequirement(address _reserve)
        external
        view
        returns (uint256)
    {
        return securityDepositRequirement[_reserve];
    }

    function getMaxSecurityDeposit(address _reserve)
        external
        view
        onlyProxy
        returns (uint256)
    {
        return maxSecurityDeposit[_reserve];
    }

    function underlyingBalance(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) public view returns (uint256) {
        address vaultAddress = _getVault(_vaultUser);
        return Vault(vaultAddress).underlyingBalance(_sponsor, _reserve);
    }

    /**
     * @dev Get available credit
     * @param _user user address
     * @param _reserve reserve address
     **/
    function getAvailableCredit(address _user, address _reserve)
        public
        view
        returns (uint256)
    {
        uint256 creditLimit = getCreditLimit(_user, _reserve);
        uint256 accumulatedDebt = Vault(_getVault(_user)).getTotalDebt();
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
        uint256 securityDepositRequirement = securityDepositRequirement[
            _reserve
        ];
        require(
            securityDepositRequirement != 0,
            'security deposit requirement cannot be 0'
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
        Voyager v = Voyager(voyager);
        address resolver = v.getAddressResolverAddress();
        return AddressResolver(resolver).getAddress(v.getVaultStorageName());
    }

    function getSecurityDepositTokenAddress(address vault)
        private
        view
        returns (address)
    {
        return Vault(vault).getSecurityDepositTokenAddress();
    }

    /**
     * @dev Get existing Vault contract address for user
     * @param _user the address of the player
     * @return Vault address
     **/
    function getVault(address _user) external view returns (address) {
        return _getVault(_user);
    }

    function eligibleAmount(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) public view returns (uint256) {
        address vaultAddress = _getVault(_vaultUser);
        return Vault(vaultAddress).eligibleAmount(_reserve, _sponsor);
    }

    /************************************** Private Functions **************************************/

    function _getSecurityDeposit(address _user, address _reserve)
        internal
        view
        returns (uint256)
    {
        address vaultAddress = _getVault(_user);
        uint256 currentSecurityDeposit = Vault(vaultAddress)
            .getCurrentSecurityDeposit(_reserve);
        return currentSecurityDeposit;
    }

    function _getVault(address _user) internal view returns (address) {
        return VaultStorage(getVaultStorageAddress()).getVaultAddress(_user);
    }

    function _requireCallerAdmin(address _caller) internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(aclManager.isVaultManager(_caller), 'Not vault admin');
    }
}

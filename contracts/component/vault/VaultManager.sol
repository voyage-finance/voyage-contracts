// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../interfaces/IVaultManager.sol';
import '../../interfaces/IAddressResolver.sol';
import '../../interfaces/IVaultFactory.sol';
import '../../interfaces/IVault.sol';
import '../../interfaces/IACLManager.sol';
import './VaultStorage.sol';
import './VaultFactory.sol';

contract VaultManager is ReentrancyGuard, Proxyable, IVaultManager {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    IAddressResolver public addressResolver;
    address public voyager;
    address public vaultFactory;
    mapping(address => uint256) public maxSecurityDeposit;
    // reserve address => requirement expressed in ray
    mapping(address => uint256) public securityDepositRequirement;

    constructor(
        address payable _proxy,
        address _addressResolver,
        address _voyager,
        address _vaultFactory
    ) public Proxyable(_proxy) {
        addressResolver = IAddressResolver(_addressResolver);
        voyager = _voyager;
        vaultFactory = _vaultFactory;
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
        require(vault != address(0), 'deploy vault failed');
        uint256 len = VaultStorage(getVaultStorageAddress()).pushNewVault(
            _user,
            vault
        );
        proxy._emit(
            abi.encode(vault, len),
            2,
            keccak256('VaultCreated(address, address, uint256)'),
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
        IVault(_vault).initialize(voyager, securityDepositEscrow);
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
        console.log(vaultAddress);
        IVault(vaultAddress).depositSecurity(_sponsor, _reserve, _amount);
        _emit(
            _sponsor,
            _vaultUser,
            _reserve,
            _amount,
            keccak256('SecurityDeposited(address, address, address, uint256)')
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
        Vault(vaultAddress).redeemSecurity(_sponsor, _reserve, _amount);
        proxy._emit(
            abi.encode(_vaultUser, _reserve, _amount),
            2,
            keccak256('SecurityRedeemed(address, address, address, uint256)'),
            bytes32(abi.encodePacked(_sponsor)),
            0,
            0
        );
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
        maxSecurityDeposit[_reserve] = _amount;
    }

    /**
     * @dev Remove max security deposit for _reserve
     * @param _reserve reserve address
     */
    function removeMaxSecurityDeposit(address _reserve)
        external
        onlyProxy
        onlyAdmin
    {
        delete maxSecurityDeposit[_reserve];
    }

    /**
     * @dev Update the security deposit requirement
     * @param _reserve reserve address
     * @param _requirement expressed in Ray
     */
    function updateSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) external onlyProxy onlyAdmin {
        securityDepositRequirement[_reserve] = _requirement;
    }

    /**
     * @dev Remove security deposit
     * @param _reserve reserve address
     */
    function removeSecurityDepositRequirement(address _reserve)
        external
        onlyProxy
        onlyAdmin
    {
        delete securityDepositRequirement[_reserve];
    }

    /************************************** View Functions **************************************/

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
        console.log('in getMaxSecurityDeposit');
        return maxSecurityDeposit[_reserve];
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
        uint256 accumulatedDebt = IVault(_getVault(_user)).getTotalDebt();
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

    function eligibleAmount(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) public view returns (uint256) {
        address vaultAddress = _getVault(_vaultUser);
        return IVault(vaultAddress).eligibleAmount(_reserve, _sponsor);
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
            addressResolver.getAddress('aclManager')
        );
        require(aclManager.isVaultManager(messageSender), 'Not vault admin');
    }
}

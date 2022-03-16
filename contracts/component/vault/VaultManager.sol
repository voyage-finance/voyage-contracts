// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Vault.sol';
import '../../interfaces/IVaultManager.sol';
import '../Voyager.sol';
import '../infra/AddressResolver.sol';
import './VaultStorage.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../tokenization/SecurityDepositToken.sol';
import '../../mock/Tus.sol';
import '../../libraries/math/WadRayMath.sol';

contract VaultManager is AccessControl, ReentrancyGuard, Proxyable {
    using SafeERC20 for ERC20;
    using WadRayMath for uint256;

    bytes32 public constant VOYAGER = keccak256('VOYAGER');
    address public voyager;
    mapping(address => uint256) public maxSecurityDeposit;
    // reserve address => requirement expressed in ray
    mapping(address => uint256) public securityDepositRequirement;

    event VaultCreated(address indexed user, address vault, uint256 len);

    event SecurityDeposited(
        address indexed sponsor,
        address user,
        address reserve,
        uint256 amount
    );

    event SecurityRedeemed(
        address indexed sponsor,
        address user,
        address reserve,
        uint256 amount
    );

    event SecurityDepositRequirementSet(
        address indexed reserve,
        uint256 requirement
    );

    constructor(address payable _proxy, address _voyager)
        public
        Proxyable(_proxy)
    {
        voyager = _voyager;
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
    function getVault(address _user) public view returns (address) {
        return VaultStorage(getVaultStorageAddress()).getVaultAddress(_user);
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
        address vaultAddress = getVault(_user);
        uint256 currentSecurityDeposit = Vault(vaultAddress)
            .getCurrentSecurityDeposit(_reserve);
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
        address vaultAddress = getVault(_vaultUser);
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
        address vaultAddress = getVault(_vaultUser);
        Vault(vaultAddress).redeemSecurity(_sponsor, _reserve, _amount);
        emit SecurityRedeemed(_sponsor, _vaultUser, _reserve, _amount);
    }

    function initSecurityDepositToken(address _vaultUser, address _reserve)
        external
        onlyProxy
    {
        address vaultAddress = getVault(_vaultUser);
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
        address vaultAddress = getVault(_vaultUser);
        Vault(vaultAddress).initStakingContract(_reserve);
    }

    /************************ HouseKeeping Function ******************************/

    function setMaxSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyProxy
    {
        maxSecurityDeposit[_reserve] = _amount;
    }

    function removeMaxSecurityDeposit(address _reserve) external onlyProxy {
        delete maxSecurityDeposit[_reserve];
    }

    function getMaxSecurityDeposit(address _reserve)
        external
        view
        onlyProxy
        returns (uint256)
    {
        return maxSecurityDeposit[_reserve];
    }

    function updateSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) external onlyProxy {
        securityDepositRequirement[_reserve] = _requirement;
        emit SecurityDepositRequirementSet(_reserve, _requirement);
    }

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
}

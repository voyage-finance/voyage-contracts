// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/ownership/Ownable.sol';
import '../component/infra/AddressResolver.sol';
import '../component/vault/VaultManager.sol';
import '../component/vault/VaultManagerProxy.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import '../libraries/acl/ExtCallACL.sol';
import '../libraries/acl/ExtCallACLProxy.sol';

contract Voyager is AccessControl {
    bytes32 public constant liquidityManagerProxyName =
        'liquidityManagerProxyName';
    bytes32 public constant loanManagerName = 'loanManager';
    bytes32 public constant vaultManagerProxyName = 'vaultManagerProxy';
    bytes32 public constant vaultStorageName = 'vaultStorage';
    bytes32 public constant securityDepositTokenName = 'securityDepositToken';
    bytes32 public constant extCallACLProxyName = 'extCallACLProxy';
    bytes32 public constant OPERATOR = keccak256('OPERATOR');

    address public addressResolver;

    modifier onlyWhitelisted(bytes32 func) {
        require(
            ExtCallACL(getExtCallACLProxyAddress()).isWhitelistedAddress(
                msg.sender
            ),
            'Voyager: not whitelisted address'
        );
        require(
            ExtCallACL(getExtCallACLProxyAddress()).isWhitelistedFunction(func),
            'Voyager: not whitelisted functions'
        );
        _;
    }

    constructor(address _operator) public {
        _setupRole(OPERATOR, _operator);
    }

    event CallResult(bool, bytes);

    /************************************** Getter Functions **************************************/

    function getVaultManagerProxyName() external view returns (bytes32) {
        return vaultManagerProxyName;
    }

    function getVaultStorageName() external view returns (bytes32) {
        return vaultStorageName;
    }

    function getLiquidityManagerProxyName() external view returns (bytes32) {
        return liquidityManagerProxyName;
    }

    function getLoanManagerName() external view returns (bytes32) {
        return loanManagerName;
    }

    function getSecurityDepositTokenName() external view returns (bytes32) {
        return securityDepositTokenName;
    }

    function getExtCallACLProxyName() external view returns (bytes32) {
        return extCallACLProxyName;
    }

    /************************************** HouseKeeping Interfaces **************************************/
    /**
     * @dev Update addressResolver contract address
     * @param _addressResolver address of the resolver contract
     **/
    function setAddressResolverAddress(address _addressResolver)
        external
        onlyRole(OPERATOR)
    {
        addressResolver = _addressResolver;
    }

    function claimVaultManagerProxyOwnership() external onlyRole(OPERATOR) {
        address payable vaultManagerProxyAddress = getVaultManagerProxyAddress();
        VaultManagerProxy(vaultManagerProxyAddress).claimOwnership();
    }

    function claimExtCallACLProxyOwnership() external onlyRole(OPERATOR) {
        address payable extCallACLProxyAddress = getExtCallACLProxyAddress();
        ExtCallACLProxy(extCallACLProxyAddress).claimOwnership();
    }

    //todo consider merge all this setting functions, define a data struct for it

    /**
     * @dev Set max security deposit for _reserve
     * @param _reserve reserve address
     * @param _amount max amount sponsor can deposit
     */
    function setMaxSecurityDeposit(address _reserve, uint256 _amount)
        external
        onlyRole(OPERATOR)
    {
        return
            VaultManager(getVaultManagerProxyAddress()).setMaxSecurityDeposit(
                _reserve,
                _amount
            );
    }

    /**
     * @dev Remove max security deposit for _reserve
     * @param _reserve reserve address
     */
    function removeMaxSecurityDeposit(address _reserve)
        external
        onlyRole(OPERATOR)
    {
        return
            VaultManager(getVaultManagerProxyAddress())
                .removeMaxSecurityDeposit(_reserve);
    }

    /**
     * @dev Update the security deposit requirement
     * @param _reserve reserve address
     * @param _requirement expressed in Ray
     */
    function updateSecurityDepositRequirement(
        address _reserve,
        uint256 _requirement
    ) external onlyRole(OPERATOR) {
        return
            VaultManager(getVaultManagerProxyAddress())
                .updateSecurityDepositRequirement(_reserve, _requirement);
    }

    /**
     * @dev Remove security deposit
     * @param _reserve reserve address
     */
    function removeSecurityDepositRequirement(address _reserve)
        external
        onlyRole(OPERATOR)
    {
        return
            VaultManager(getVaultManagerProxyAddress())
                .removeSecurityDepositRequirement(_reserve);
    }

    /**
     * Init a deployed Vault, ensure it has overlying security deposit token and corresponding staking contract
     * _vaultUser the user/owner of this vault
     * _reserve the underlying asset address e.g. TUS
     **/
    function initVault(address _user, address _reserve)
        external
        onlyRole(OPERATOR)
    {
        VaultManager vaultManager = VaultManager(getVaultManagerProxyAddress());
        vaultManager.initSecurityDepositToken(_user, _reserve);
        vaultManager.initStakingContract(_user, _reserve);
    }

    function whitelistAddress(address[] calldata _address)
        external
        onlyRole(OPERATOR)
    {
        ExtCallACL extCallACL = ExtCallACL(getExtCallACLProxyAddress());
        extCallACL.whitelistAddress(_address);
    }

    function whitelistFunction(bytes32[] calldata _function)
        external
        onlyRole(OPERATOR)
    {
        ExtCallACL extCallACL = ExtCallACL(getExtCallACLProxyAddress());
        extCallACL.whitelistFunction(_function);
    }

    /************************************** Vault Manager Interfaces **************************************/

    /**
     * @dev Create an empty Vault for msg.sender, in addition to this, a vault also deploy
     * a SecurityDepositEscrow contract which the fund will be held in
     × @return address of Vault
     **/
    function createVault()
        external
        onlyWhitelisted('createVault')
        returns (address)
    {
        address vaultManagerProxy = getVaultManagerProxyAddress();
        VaultManager vaultManager = VaultManager(vaultManagerProxy);
        return vaultManager.createVault(msg.sender);
    }

    /**
     * @dev Deposit specific amount of security deposit to user owned Vault
     * @param _vaultUser the user address that will be sponsored
     * @param _reserve address of reserve
     * @param _amount deposit amount
     **/
    function depositSecurity(
        address _vaultUser,
        address _reserve,
        uint256 _amount
    ) external onlyWhitelisted('depositSecurity') {
        VaultManager(getVaultManagerProxyAddress()).depositSecurity(
            msg.sender,
            _vaultUser,
            _reserve,
            _amount
        );
    }

    /**
     * @dev Get underlying balance of security deposit token
     * @param _vaultUser _vaultUser the user address that has be sponsored
     * @param _reserve address of reserve
     * @param _sponsor sponsor address
     **/
    function underlyingBalance(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) external view returns (uint256) {
        return
            VaultManager(getVaultManagerProxyAddress()).underlyingBalance(
                _vaultUser,
                _reserve,
                _sponsor
            );
    }

    /**
     * @dev Redeem specific amount of security deposit to user owned Vault
     * @param _vaultUser the user address that has be sponsored
     * @param _reserve address of reserve
     * @param _amount deposit amount
     **/
    function redeemSecurity(
        address _vaultUser,
        address _reserve,
        uint256 _amount
    ) external onlyWhitelisted('redeemSecurity') {
        VaultManager(getVaultManagerProxyAddress()).redeemSecurity(
            payable(msg.sender),
            _vaultUser,
            _reserve,
            _amount
        );
    }

    // todo placeholder functions, more detail should be impl in the future
    function slash(
        address _vaultUser,
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external {
        VaultManager(getVaultManagerProxyAddress()).slash(
            _vaultUser,
            _reserve,
            _to,
            _amount
        );
    }

    /**
     * @dev Get maximum reserve amount the use can borrow
     * @param _user user address
     * @param _reserve reserve contract address
     **/
    function getCreditLimit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return
            VaultManager(getVaultManagerProxyAddress()).getCreditLimit(
                _user,
                _reserve
            );
    }

    /**
     * @dev Eligible amount that can be withdraw, calculated by deposit records without considering slash
     * @param _vaultUser user address
     * @param _reserve reserve address
     * @param _sponsor sponsor address
     **/
    function eligibleAmount(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) external view returns (uint256) {
        return
            VaultManager(getVaultManagerProxyAddress()).eligibleAmount(
                _vaultUser,
                _reserve,
                _sponsor
            );
    }

    /************************************** View Interfaces **************************************/

    /**
     * @dev Get max security deposit for _reserve
     * @param _reserve reserve address
     * @return max deposit amount
     */
    function getMaxSecurityDeposit(address _reserve)
        external
        view
        returns (uint256)
    {
        return
            VaultManager(getVaultManagerProxyAddress()).getMaxSecurityDeposit(
                _reserve
            );
    }

    /**
     * @dev Get current security deposit requirement
     * @param _reserve reserve address
     * @return requirement, expressed in Ray
     **/
    function getSecurityDepositRequirement(address _reserve)
        external
        view
        returns (uint256)
    {
        return
            VaultManager(getVaultManagerProxyAddress())
                .getSecurityDepositRequirement(_reserve);
    }

    /**
     * @dev Get addressResolver contract address
     * @return address of the resolver contract
     **/
    function getAddressResolverAddress() external view returns (address) {
        return addressResolver;
    }

    /**
     * @dev Get VaultManagerProxy contract address
     * @return address of the VaultManager
     **/
    function getVaultManagerProxyAddress()
        public
        view
        returns (address payable)
    {
        address vaultManagerProxyAddress = AddressResolver(addressResolver)
            .getAddress(vaultManagerProxyName);
        return payable(vaultManagerProxyAddress);
    }

    /**
     * @dev Get ExtCallACLProxy contract address
     **/
    function getExtCallACLProxyAddress() public view returns (address payable) {
        address extCallACLProxyAddress = AddressResolver(addressResolver)
            .getAddress(extCallACLProxyName);
        return payable(extCallACLProxyAddress);
    }
}

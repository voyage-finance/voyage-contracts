// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/ownership/Ownable.sol';
import '../component/infra/AddressResolver.sol';
import '../component/vault/VaultManager.sol';
import '../component/vault/VaultManagerProxy.sol';
import 'openzeppelin-solidity/contracts/access/AccessControl.sol';

contract Voyager is AccessControl {
    bytes32 public constant liquidityManagerName = 'liquidityManager';
    bytes32 public constant loanManagerName = 'loanManager';
    bytes32 public constant vaultManagerProxyName = 'vaultManagerProxy';
    bytes32 public constant vaultStorageName = 'vaultStorage';
    bytes32 public constant OPERATOR = keccak256('OPERATOR');

    address public addressResolver;

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

    function getLiquidityManagerName() external view returns (bytes32) {
        return liquidityManagerName;
    }

    function getLoanManagerName() external view returns (bytes32) {
        return loanManagerName;
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

    /************************************** Vault Manager Interfaces **************************************/

    /**
     * @dev Create an empty Vault for msg.sender, in addition to this, a vault also deploy
     * a SecurityDepositEscrow contract which the fund will be held in
     × @return address of Vault
     **/
    function createVault() external returns (address) {
        address vaultManagerProxy = getVaultManagerProxyAddress();
        VaultManager vaultManager = VaultManager(vaultManagerProxy);
        return vaultManager.createVault(msg.sender);
    }

    /**
     * @dev Deposit specific amount of security deposit to user owned Vault
     * @param _reserve address of reserve
     * @param _amount deposit amount
     **/
    function depositSecurity(address _reserve, uint256 _amount) external {
        VaultManager(getVaultManagerProxyAddress()).depositSecurity(
            msg.sender,
            _reserve,
            _amount
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
}

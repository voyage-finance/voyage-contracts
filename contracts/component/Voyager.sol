// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import '../libraries/acl/ExtCallACL.sol';
import '../libraries/acl/ExtCallACLProxy.sol';
import '../libraries/ownership/Ownable.sol';
import '../libraries/types/DataTypes.sol';
import '../libraries/logic/ReserveLogic.sol';
import '../component/infra/AddressResolver.sol';
import '../component/vault/VaultManager.sol';
import '../component/vault/VaultManagerProxy.sol';
import '../component/liquidity/LiquidityManager.sol';
import '../component/loan/LoanManager.sol';
import '../interfaces/IACLManager.sol';
import './infra/MessageBus.sol';
import 'hardhat/console.sol';

contract Voyager is MessageBus {
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

    modifier onlyProtocolManager() {
        _requireCallerAdmin();
        _;
    }

    event CallResult(bool, bytes);

    /************************************** HouseKeeping Interfaces **************************************/
    /**
     * @dev Update addressResolver contract address
     * @param _addressResolver address of the resolver contract
     **/
    function setAddressResolverAddress(address _addressResolver)
        external
        onlyOwner
    {
        addressResolver = AddressResolver(_addressResolver);
    }

    function whitelistAddress(address[] calldata _address)
        external
        onlyProtocolManager
    {
        ExtCallACL extCallACL = ExtCallACL(getExtCallACLProxyAddress());
        extCallACL.whitelistAddress(_address);
    }

    function whitelistFunction(bytes32[] calldata _function)
        external
        onlyProtocolManager
    {
        ExtCallACL extCallACL = ExtCallACL(getExtCallACLProxyAddress());
        extCallACL.whitelistFunction(_function);
    }

    /************************************** Liquidity Manager Interfaces **************************************/

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying tokens: Either
     * Junior Deposit Token or Senior Deposit token
     * @param _asset The address of the underlying asset to deposit
     * @param _tranche The tranche of the liquidity pool the user wants to deposit to
     * @param _amount The amount to be deposited
     **/
    function deposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount
    ) external {
        LiquidityManager(getLiquidityManagerProxyAddress()).deposit(
            _asset,
            _tranche,
            _amount,
            msg.sender
        );
    }

    function withdraw(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount
    ) external {
        LiquidityManager(getLiquidityManagerProxyAddress()).withdraw(
            _asset,
            _tranche,
            _amount,
            payable(msg.sender)
        );
    }

    /**
     * @dev Returns the normalized income per unit of asset
     * @param _asset The address of the underlying asset of the reserve
     * @param _tranche The tranche of the reserve, either Junior or Senior
     * @return The reserve's normalized income
     **/
    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        return
            LiquidityManager(getLiquidityManagerProxyAddress())
                .getReserveNormalizedIncome(_asset, _tranche);
    }

    /**
     * @dev Returns the reserve flags
     * @param _asset The address of asset
     * @return The state flags representing active, frozen, borrowing enabled
     **/
    function getReserveFlags(address _asset)
        external
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return
            LiquidityManager(getLiquidityManagerProxyAddress()).getFlags(
                _asset
            );
    }

    /**
     * @dev Returns the configuration of the reserve
     * @param _asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getConfiguration(address _asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManager(getLiquidityManagerProxyAddress())
                .getConfiguration(_asset);
    }

    /**
     * @dev Get current liquidity rate for a specific reserve for it junior tranche or senior tranche
     * @param _asset The address of the underlying asset of the reserve
     * @param _tranche Either junior tranche or senior tranche
     **/
    function liquidityRate(address _asset, ReserveLogic.Tranche _tranche)
        external
        view
        returns (uint256)
    {
        return
            LiquidityManager(getLiquidityManagerProxyAddress())
                .getLiquidityRate(_asset, _tranche);
    }

    /************************************** Loan Manager Interfaces **************************************/

    // todo remove _grossAssetValue
    function borrow(
        address _asset,
        uint256 _amount,
        address payable _vault,
        uint256 _grossAssetValue
    ) external onlyWhitelisted('borrow') {
        LoanManager(addressResolver.getLoanManagerProxy()).borrow(
            msg.sender,
            _asset,
            _amount,
            _vault,
            _grossAssetValue
        );
    }

    function repay(
        address _asset,
        uint256 _drawDownIdx,
        address payable _vault
    ) external {
        LoanManager(addressResolver.getLoanManagerProxy()).repay(
            msg.sender,
            _asset,
            _drawDownIdx,
            _vault
        );
    }

    /************************************** Vault Manager Interfaces **************************************/

    /**
     * @dev Create an empty Vault for msg.sender, in addition to this, a vault also deploy
     * a SecurityDepositEscrow contract which the fund will be held in
     × @return address of Vault
     **/
    function createVault(
        address _to,
        address _reserve,
        bytes32 _salt
    ) external onlyWhitelisted('createVault') returns (address) {
        address vaultManagerProxy = getVaultManagerProxyAddress();
        VaultManager vaultManager = VaultManager(vaultManagerProxy);
        return vaultManager.createVault(_to, _reserve, _salt);
    }

    function initVault(address _vault, address _reserve) external {
        address vaultManagerProxy = getVaultManagerProxyAddress();
        VaultManager vaultManager = VaultManager(vaultManagerProxy);
        vaultManager.initVault(_vault, _reserve);
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
            VaultManagerProxy(getVaultManagerProxyAddress()).getCreditLimit(
                _user,
                _reserve
            );
    }

    /**
     * @dev Get available credit
     * @param _user user address
     * @param _reserve address of reserve
     **/
    function getAvailableCredit(address _user, address _reserve)
        external
        view
        returns (uint256)
    {
        return
            VaultManagerProxy(getVaultManagerProxyAddress()).getAvailableCredit(
                _user,
                _reserve
            );
    }

    // deprecated
    function eligibleAmount(
        address _vaultUser,
        address _reserve,
        address _sponsor
    ) external view returns (uint256) {
        return
            VaultManager(getVaultManagerProxyAddress()).getWithdrawableDeposit(
                _vaultUser,
                _reserve,
                _sponsor
            );
    }

    /************************************** View Interfaces **************************************/

    /**
     * @dev Get ExtCallACLProxy contract address
     **/
    function getExtCallACLProxyAddress() public view returns (address payable) {
        address extCallACLProxyAddress = AddressResolver(addressResolver)
            .getExtCallProxy();
        return payable(extCallACLProxyAddress);
    }

    /************************************** Internal Interfaces **************************************/

    function _requireCallerAdmin() internal view {
        IACLManager aclManager = IACLManager(addressResolver.getAclManager());
        require(aclManager.isProtocolManager(tx.origin), 'Not vault admin');
    }
}

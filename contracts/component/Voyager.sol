// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ExtCallACL} from "../libraries/acl/ExtCallACL.sol";
import {ExtCallACLProxy} from "../libraries/acl/ExtCallACLProxy.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {AddressResolver} from "../component/infra/AddressResolver.sol";
import {VaultManager} from "../component/vault/VaultManager.sol";
import {VaultManagerProxy} from "../component/vault/VaultManagerProxy.sol";
// import {LoanManager} from "../component/loan/LoanManager.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {MessageBus} from "./infra/MessageBus.sol";
import {Diamond} from "../diamond/Diamond.sol";
import {LibDiamond} from "../diamond/libraries/LibDiamond.sol";

contract Voyager is Diamond, MessageBus {
    modifier onlyWhitelisted(bytes32 func) {
        require(
            ExtCallACL(getExtCallACLProxyAddress()).isWhitelistedAddress(
                msg.sender
            ),
            "Voyager: not whitelisted address"
        );
        require(
            ExtCallACL(getExtCallACLProxyAddress()).isWhitelistedFunction(func),
            "Voyager: not whitelisted functions"
        );
        _;
    }

    modifier onlyProtocolManager() {
        _requireCallerAdmin();
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner());
        _;
    }

    event CallResult(bool, bytes);

    constructor(address _owner) Diamond(_owner) {}

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

    /************************************** Loan Manager Interfaces **************************************/

    // todo remove _grossAssetValue
    // function borrow(
    //     address _asset,
    //     uint256 _amount,
    //     address payable _vault,
    //     uint256 _grossAssetValue
    // ) external onlyWhitelisted("borrow") {
    //     LoanManager(this.addressResolver().getLoanManagerProxy()).borrow(
    //         msg.sender,
    //         _asset,
    //         _amount,
    //         _vault,
    //         _grossAssetValue
    //     );
    // }

    // function repay(
    //     address _asset,
    //     uint256 _drawDownIdx,
    //     address payable _vault
    // ) external {
    //     LoanManager(this.addressResolver().getLoanManagerProxy()).repay(
    //         msg.sender,
    //         _asset,
    //         _drawDownIdx,
    //         _vault
    //     );
    // }

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
    ) external onlyWhitelisted("createVault") returns (address) {
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
    ) external onlyWhitelisted("depositSecurity") {
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
    ) external onlyWhitelisted("redeemSecurity") {
        VaultManager(getVaultManagerProxyAddress()).redeemSecurity(
            payable(msg.sender),
            _vaultUser,
            _reserve,
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
        address extCallACLProxyAddress = AddressResolver(_addressResolver())
            .getExtCallProxy();
        return payable(extCallACLProxyAddress);
    }

    /************************************** Internal Interfaces **************************************/

    function _requireCallerAdmin() internal view {
        IACLManager aclManager = IACLManager(
            this.addressResolver().getAclManager()
        );
        require(aclManager.isProtocolManager(tx.origin), "Not vault admin");
    }
}

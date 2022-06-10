// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SecurityDepositEscrow} from "./SecurityDepositEscrow.sol";
import {AddressResolver} from "../infra/AddressResolver.sol";
import {Voyager} from "../Voyager.sol";
import {VaultManager} from "./VaultManager.sol";
import {StakingRewards} from "../staking/StakingRewards.sol";
import {LoanManagerProxy} from "../loan/LoanManagerProxy.sol";
import {SecurityDepositToken} from "../../tokenization/SecurityDepositToken.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {ILoanManager} from "../../interfaces/ILoanManager.sol";
import {IVaultManagerProxy} from "../../interfaces/IVaultManagerProxy.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";

contract Vault is ReentrancyGuard, IVault {
    using WadRayMath for uint256;
    using SafeMath for uint256;
    bytes32 public constant BORROWER = keccak256("BORROWER");

    address payable public voyager;
    address[] public players;
    bool public initialized;
    SecurityDepositEscrow public securityDepositEscrow;
    SecurityDepositToken public securityDepositToken;
    StakingRewards public stakingContract;

    //    uint256 public totalDebt;
    // todo oracle
    uint256 public gav;

    modifier onlyLoanManager() {
        _requireCallerLoanManager();
        _;
    }

    modifier onlyVaultManager() {
        _requireVaultManager();
        _;
    }

    modifier onlyVaultManagerContract() {
        _requireCallerLoanManagerContract();
        _;
    }

    function initialize(
        address _voyager,
        SecurityDepositEscrow _securityDepositEscrow
    ) external {
        if (!initialized) {
            voyager = payable(_voyager);
            securityDepositEscrow = _securityDepositEscrow;
            initialized = true;
        }
    }

    function initSecurityDepositToken(address _reserve)
        external
        onlyVaultManager
    {
        require(
            address(securityDepositToken) == address(0),
            "Vault: security deposit token has been initialized"
        );
        ERC20 token = ERC20(_reserve);
        securityDepositToken = new SecurityDepositToken(
            _reserve,
            token.decimals(),
            token.name(),
            token.symbol()
        );
    }

    function initStakingContract(address _reserve) external onlyVaultManager {
        require(
            address(stakingContract) == address(0),
            "Vault: staking contract has been initialized"
        );
        require(
            address(securityDepositToken) != address(0),
            "Vault: security deposit token has not been initialized"
        );
        stakingContract = new StakingRewards(
            address(securityDepositToken),
            _reserve
        );
    }

    /**
     * @dev Transfer some deposit security
     * @param _sponsor user address who deposit to this escrow
     * @param _reserve reserve address
     * @param _amount deposit amount
     **/
    function depositSecurity(
        address _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVaultManager {
        address vmp = Voyager(voyager).addressResolver().getVaultManagerProxy();
        IVaultManagerProxy vaultManagerProxy = IVaultManagerProxy(vmp);
        DataTypes.VaultConfig memory vaultConfig = vaultManagerProxy
            .getVaultConfig(_reserve);

        // check max security deposit amount for this _reserve
        uint256 maxAllowedAmount = vaultConfig.maxSecurityDeposit;
        uint256 depositedAmount = securityDepositEscrow.getDepositAmount(
            _reserve
        );
        require(
            depositedAmount + _amount < maxAllowedAmount,
            "Vault: deposit amount exceed"
        );

        // check min security deposit amount for this _reserve
        uint256 minAllowedAmount = vaultConfig.minSecurityDeposit;
        require(minAllowedAmount <= _amount, "Vault: deposit too small");

        securityDepositEscrow.deposit(_reserve, _sponsor, _amount);
        securityDepositToken.mintOnDeposit(_sponsor, _amount);
    }

    /**
     * @dev Redeem underlying reserve
     * @param _sponsor sponsor address
     * @param _reserve reserve address
     * @param _amount redeem amount
     **/
    function redeemSecurity(
        address payable _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable nonReentrant onlyVaultManager {
        require(
            _amount <= _getWithdrawableDeposit(_sponsor, _reserve),
            "Vault: cannot redeem more than withdrawable deposit amount"
        );
        securityDepositEscrow.withdraw(
            _reserve,
            _sponsor,
            _underlyingBalance(_sponsor, _reserve)
        );
        securityDepositToken.burnOnRedeem(_sponsor, _amount);
    }

    // placeholder function
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external nonReentrant onlyVaultManager {
        securityDepositEscrow.slash(_reserve, _to, _amount);
    }

    /************************************** View Functions **************************************/

    /**
     * @dev get current security amount
     * @param _reserve underlying asset address
     **/
    function getCurrentSecurityDeposit(address _reserve)
        external
        view
        returns (uint256)
    {
        return securityDepositEscrow.getDepositAmount(_reserve);
    }

    function getActualSecurityDeposit(address _reserve)
        public
        view
        returns (uint256)
    {
        return ERC20(_reserve).balanceOf(address(securityDepositEscrow));
    }

    function getGav() external view returns (uint256) {
        return gav;
    }

    function getWithdrawableDeposit(address _sponsor, address _reserve)
        external
        view
        returns (uint256)
    {
        return _getWithdrawableDeposit(_sponsor, _reserve);
    }

    function underlyingBalance(address _sponsor, address _reserve)
        external
        view
        returns (uint256)
    {
        return _underlyingBalance(_sponsor, _reserve);
    }

    function getSecurityDepositTokenAddress() external view returns (address) {
        return address(securityDepositToken);
    }

    function getStakingContractAddress() external view returns (address) {
        return address(stakingContract);
    }

    /**
     * @dev Get SecurityDepositEscrow contract address
     * @return address
     **/
    function getSecurityDepositEscrowAddress() external view returns (address) {
        return address(securityDepositEscrow);
    }

    function getVersion() external view returns (string memory) {
        string memory version = "Vault 0.0.1";
        return version;
    }

    /************************************** Internal Functions **************************************/

    function _requireCallerLoanManager() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAclManager()
        );
        require(
            aclManager.isLoanManager(msg.sender),
            "Not loan manager contract"
        );
    }

    function _requireCallerLoanManagerContract() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAclManager()
        );
        require(
            aclManager.isLoanManagerContract(msg.sender),
            "Not loan manager"
        );
    }

    function _requireVaultManager() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAclManager()
        );
        require(
            aclManager.isVaultManagerContract(msg.sender),
            "Not vault manager contract"
        );
    }

    function _getVaultManagerAddress() internal view returns (address) {
        Voyager v = Voyager(voyager);
        return v.addressResolver().getVaultManager();
    }

    function _underlyingBalance(address _sponsor, address _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 amountToRedeemInRay = securityDepositToken
            .balanceOf(_sponsor)
            .wadToRay()
            .rayDiv(securityDepositToken.totalSupply().wadToRay())
            .rayMul(getActualSecurityDeposit(_reserve).wadToRay());
        return amountToRedeemInRay.rayToWad();
    }

    function getVaultManagerProxyAddress() private view returns (address) {
        Voyager voyager = Voyager(voyager);
        address addressResolver = voyager.getAddressResolverAddress();
        return AddressResolver(addressResolver).getVaultManagerProxy();
    }

    function getLoanManagerProxyAddress() private view returns (address) {
        Voyager voyager = Voyager(voyager);
        address addressResolver = voyager.getAddressResolverAddress();
        return AddressResolver(addressResolver).getLoanManagerProxy();
    }

    function _getUnusedDeposits(address _sponsor, address _reserve)
        internal
        view
        returns (uint256)
    {
        address vmp = Voyager(voyager).addressResolver().getVaultManagerProxy();
        IVaultManagerProxy vaultManagerProxy = IVaultManagerProxy(vmp);
        DataTypes.VaultConfig memory vaultConfig = vaultManagerProxy
            .getVaultConfig(_reserve);

        uint256 securityRequirement = vaultConfig.securityDepositRequirement;
        uint256 principal;
        uint256 interest;
        (principal, interest) = ILoanManager(getLoanManagerProxyAddress())
            .getVaultDebt(_reserve, address(this));

        uint256 totalDebt = principal.add(interest);
        return
            securityDepositToken.balanceOf(_sponsor) -
            totalDebt.wadToRay().rayMul(securityRequirement).rayToWad();
    }

    function _eligibleAmount(address _reserve, address _sponsor)
        internal
        view
        returns (uint256)
    {
        return securityDepositEscrow.eligibleAmount(_reserve, _sponsor);
    }

    function _getWithdrawableDeposit(address _sponsor, address _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 withdrawableAmount = _getUnusedDeposits(_sponsor, _reserve);
        uint256 eligibleAmount = _eligibleAmount(_reserve, _sponsor);
        if (eligibleAmount < withdrawableAmount) {
            withdrawableAmount = eligibleAmount;
        }
        return withdrawableAmount;
    }
}

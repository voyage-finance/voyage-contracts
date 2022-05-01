// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import './SecurityDepositEscrow.sol';
import '../infra/AddressResolver.sol';
import '../Voyager.sol';
import '../staking/StakingRewards.sol';
import '../../tokenization/SecurityDepositToken.sol';
import '../../tokenization/StableDebtToken.sol';
import '../../libraries/math/WadRayMath.sol';
import '../../interfaces/IVault.sol';
import '../../interfaces/IVaultManagerProxy.sol';
import './VaultManager.sol';
import '../../interfaces/IACLManager.sol';
import 'hardhat/console.sol';

contract Vault is ReentrancyGuard, IVault {
    using WadRayMath for uint256;
    bytes32 public constant BORROWER = keccak256('BORROWER');

    address public voyager;
    address[] public players;
    bool public initialized;
    SecurityDepositEscrow public securityDepositEscrow;
    SecurityDepositToken public securityDepositToken;
    StableDebtToken public stableDebtToken;
    StakingRewards public stakingContract;

    uint256 public totalDebt;
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
            voyager = _voyager;
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
            'Vault: security deposit token has been initialized'
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
            'Vault: staking contract has been initialized'
        );
        require(
            address(securityDepositToken) != address(0),
            'Vault: security deposit token has not been initialized'
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
            'Vault: deposit amount exceed'
        );

        // check min security deposit amount for this _reserve
        uint256 minAllowedAmount = vaultConfig.minSecurityDeposit;
        require(minAllowedAmount <= _amount, 'Vault: deposit too small');

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
            'Vault: cannot redeem more than withdrawable deposit amount'
        );
        securityDepositEscrow.withdraw(
            _reserve,
            _sponsor,
            _underlyingBalance(_sponsor, _reserve)
        );
        securityDepositToken.burnOnRedeem(_sponsor, _amount);
    }

    function increaseTotalDebt(uint256 _amount)
        external
        onlyVaultManagerContract
    {
        totalDebt += _amount;
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

    /**
     * @dev Get total debt of the vault
     **/
    function getTotalDebt() external view returns (uint256) {
        return totalDebt;
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
        string memory version = 'Vault 0.0.1';
        return version;
    }

    /************************************** Internal Functions **************************************/

    function _requireCallerLoanManager() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(
            aclManager.isLoanManager(msg.sender),
            'Not loan manager contract'
        );
    }

    function _requireCallerLoanManagerContract() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(
            aclManager.isLoanManagerContract(msg.sender),
            'Not loan manager'
        );
    }

    function _requireVaultManager() internal {
        Voyager v = Voyager(voyager);
        IACLManager aclManager = IACLManager(
            v.addressResolver().getAddress(v.getACLManagerName())
        );
        require(
            aclManager.isVaultManagerContract(msg.sender),
            'Not vault manager contract'
        );
    }

    function _getVaultManagerAddress() internal view returns (address) {
        Voyager v = Voyager(voyager);
        return v.addressResolver().getAddress(v.getVaultManagerName());
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

    function getVaultManagerProxyAddress() private returns (address) {
        Voyager voyager = Voyager(voyager);
        address addressResolver = voyager.getAddressResolverAddress();
        return AddressResolver(addressResolver).getVaultManagerProxy();
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
        console.log('sdt balance: ', securityDepositToken.balanceOf(_sponsor));
        return
            securityDepositToken.balanceOf(_sponsor) -
            totalDebt.wadToRay().rayMul(securityRequirement);
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
        console.log('unused deposit: ', withdrawableAmount);
        console.log('eligible deposit: ', eligibleAmount);
        if (eligibleAmount < withdrawableAmount) {
            withdrawableAmount = eligibleAmount;
        }
        return withdrawableAmount;
    }
}

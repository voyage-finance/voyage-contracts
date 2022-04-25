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

    function getVaultManagerProxyAddress() private returns (address) {
        Voyager voyager = Voyager(voyager);
        address addressResolver = voyager.getAddressResolverAddress();
        return
            AddressResolver(addressResolver).getAddress(
                voyager.getVaultManagerProxyName()
            );
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
        // check max security deposit amount for this _reserve
        uint256 maxAllowedAmount = Voyager(voyager).getMaxSecurityDeposit(
            _reserve
        );
        uint256 depositedAmount = securityDepositEscrow.getDepositAmount(
            _reserve
        );
        require(
            depositedAmount + _amount < maxAllowedAmount,
            'Vault: deposit amount exceed'
        );
        securityDepositEscrow.deposit(_reserve, _sponsor, _amount);
        securityDepositToken.mintOnDeposit(_sponsor, _amount);
    }

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

    /**
     * @dev Get unused deposits
     * @param _sponsor sponsor address
     * @param _reserve reserve address
     **/
    function getUnusedDeposits(address _sponsor, address _reserve)
        public
        view
        returns (uint256)
    {
        uint256 securityRequirement = VaultManager(_getVaultManagerAddress())
            .getSecurityDepositRequirement(_reserve);
        return
            securityDepositToken.balanceOf(_sponsor) -
            totalDebt.wadToRay().rayMul(securityRequirement);
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
            _amount <= getUnusedDeposits(_sponsor, _reserve),
            'Vault: cannot redeem more than unused deposits'
        );
        securityDepositEscrow.withdraw(
            _reserve,
            _sponsor,
            _underlyingBalance(_sponsor, _reserve)
        );
        securityDepositToken.burnOnRedeem(_sponsor, _amount);
    }

    function underlyingBalance(address _sponsor, address _reserve)
        external
        view
        returns (uint256)
    {
        return _underlyingBalance(_sponsor, _reserve);
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

    function eligibleAmount(address _reserve, address _sponsor)
        external
        view
        returns (uint256)
    {
        return securityDepositEscrow.eligibleAmount(_reserve, _sponsor);
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
}

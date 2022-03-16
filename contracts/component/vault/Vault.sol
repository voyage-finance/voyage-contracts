// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import './SecurityDepositEscrow.sol';
import '../infra/AddressResolver.sol';
import '../Voyager.sol';
import '../staking/StakingRewards.sol';
import '../../tokenization/SecurityDepositToken.sol';
import '../../libraries/math/WadRayMath.sol';
import './VaultManager.sol';

contract Vault is AccessControl, ReentrancyGuard {
    using WadRayMath for uint256;
    bytes32 public constant BORROWER = keccak256('BORROWER');

    address public factory;
    address public voyager;
    address[] public players;
    SecurityDepositEscrow public securityDepositEscrow;
    SecurityDepositToken public securityDepositToken;
    StakingRewards public stakingContract;

    uint256 public totalDebt;

    modifier onlyFactory() {
        require(msg.sender == factory, 'only factory error');
        _;
    }

    constructor() public {
        factory = msg.sender;
        securityDepositEscrow = SecurityDepositEscrow(deployEscrow());
    }

    function deployEscrow() private returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender));
        bytes memory bytecode = type(SecurityDepositEscrow).creationCode;
        address deployedEscrow;
        assembly {
            deployedEscrow := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }
        return deployedEscrow;
    }

    // called once by the factory at time of deployment
    function initialize(address _voyager, address borrower) external {
        require(msg.sender == factory, 'Voyager Vault: FORBIDDEN'); // sufficient check
        voyager = _voyager;
        _setupRole(BORROWER, borrower);
    }

    function getVaultManagerProxyAddress() private returns (address) {
        Voyager voyager = Voyager(voyager);
        address addressResolver = voyager.getAddressResolverAddress();
        return
            AddressResolver(addressResolver).getAddress(
                voyager.getVaultManagerProxyName()
            );
    }

    function initSecurityDepositToken(address _reserve) external onlyFactory {
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

    function initStakingContract(address _reserve) external onlyFactory {
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
    ) external payable nonReentrant onlyFactory {
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
        public
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
     * @dev Get unused deposits
     * @param _sponsor sponsor address
     * @param _reserve reserve address
     **/
    function getUnusedDeposits(address _sponsor, address _reserve)
        public
        view
        returns (uint256)
    {
        uint256 securityRequirement = VaultManager(factory)
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
    ) external payable nonReentrant onlyFactory {
        require(
            _amount <= getUnusedDeposits(_sponsor, _reserve),
            'Vault: cannot redeem more than unused deposits'
        );
        securityDepositEscrow.withdraw(
            _reserve,
            _sponsor,
            underlyingBalance(_sponsor, _reserve)
        );
        securityDepositToken.burnOnRedeem(_sponsor, _amount);
    }

    function underlyingBalance(address _sponsor, address _reserve)
        public
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
        public
        view
        returns (uint256)
    {
        return securityDepositEscrow.eligibleAmount(_reserve, _sponsor);
    }

    // placeholder function
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) public nonReentrant onlyFactory {
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
}

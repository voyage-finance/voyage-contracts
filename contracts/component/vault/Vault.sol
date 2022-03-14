// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import './SecurityDepositEscrow.sol';
import '../infra/AddressResolver.sol';
import '../Voyager.sol';
import '../staking/StakingRewards.sol';
import '../../tokenization/SecurityDepositToken.sol';

contract Vault is AccessControl, ReentrancyGuard {
    bytes32 public constant BORROWER = keccak256('BORROWER');

    address public factory;
    address public voyager;
    address[] public players;
    address public securityDepositEscrow;
    SecurityDepositToken public securityDepositToken;
    StakingRewards public stakingContract;

    modifier onlyFactory() {
        require(msg.sender == factory, 'only factory error');
        _;
    }

    constructor() public {
        factory = msg.sender;
        securityDepositEscrow = deployEscrow();
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
        ERC20 token = ERC20(_reserve);
        securityDepositToken = new SecurityDepositToken(
            _reserve,
            token.decimals(),
            token.name(),
            token.symbol()
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
        SecurityDepositEscrow escrow = SecurityDepositEscrow(
            securityDepositEscrow
        );
        uint256 depositedAmount = escrow.getDepositAmount(_reserve);
        require(
            depositedAmount + _amount < maxAllowedAmount,
            'Vault: deposit amount exceed'
        );
        SecurityDepositEscrow(securityDepositEscrow).deposit(
            _reserve,
            _sponsor,
            _amount
        );
    }

    function getCurrentSecurityDeposit(address _reserve)
        external
        view
        returns (uint256)
    {
        return
            SecurityDepositEscrow(securityDepositEscrow).getDepositAmount(
                _reserve
            );
    }

    /**
     * @dev Get SecurityDepositEscrow contract address
     * @return address
     **/
    function getSecurityDepositEscrowAddress() external view returns (address) {
        return securityDepositEscrow;
    }

    function getVersion() external view returns (string memory) {
        string memory version = 'Vault 0.0.1';
        return version;
    }
}

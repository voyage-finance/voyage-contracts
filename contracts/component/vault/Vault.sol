// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import './SecurityDepositEscrow.sol';
import '../infra/AddressResolver.sol';
import '../Voyager.sol';

contract Vault is AccessControl, ReentrancyGuard {
    bytes32 public constant BORROWER = keccak256('BORROWER');

    address public factory;
    address public voyager;
    address[] public players;
    address public securityDepositEscrow;

    constructor() public {
        factory = msg.sender;
        // deploy securityDepositEscrow
        // salt just an arbitrary value
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
        securityDepositEscrow = deployedEscrow;
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

    /**
     * @dev Transfer some deposit security
     * @param _reserve reserve address
     * @param _amount deposit amount
     **/
    function depositSecurity(address _reserve, uint256 _amount)
        external
        payable
        nonReentrant
    {
        // check max security deposit amount for this _reserve
        uint256 maxAmount = Voyager(voyager).getMaxSecurityDeposit(_reserve);
        SecurityDepositEscrow escrow = SecurityDepositEscrow(
            securityDepositEscrow
        );
        // todo check if the _reserve is allowed to be deposited
        SecurityDepositEscrow(securityDepositEscrow).deposit(
            _reserve,
            msg.sender,
            _amount
        );
    }

    // todo refactor vault contract to remove _user parameter
    function getCurrentSecurityDeposit(address _reserve, address _user)
        external
        view
        returns (uint256)
    {
        return
            SecurityDepositEscrow(securityDepositEscrow).getDepositAmount(
                _reserve,
                _user
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';
import './SecurityDepositEscrow.sol';

contract Vault is AccessControl, ReentrancyGuard {
    bytes32 public constant BORROWER = keccak256('BORROWER');

    address public factory;
    address public addressResolver;
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
    function initialize(address _addressResolver, address borrower) external {
        require(msg.sender == factory, 'Voyager Vault: FORBIDDEN'); // sufficient check
        addressResolver = _addressResolver;
        _setupRole(BORROWER, borrower);
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
        SecurityDepositEscrow(securityDepositEscrow).deposit(
            _reserve,
            msg.sender,
            _amount
        );
    }

    /**
     * @dev Get SecurityDepositEscrow contract address
     * @return address
     **/
    function getSecurityDepositEscrowAddress() external view returns (address) {
        return securityDepositEscrow;
    }
}

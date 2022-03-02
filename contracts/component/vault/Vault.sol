// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/access/AccessControl.sol';

contract Vault is AccessControl {
    bytes32 public constant BORROWER = keccak256('BORROWER');

    address public factory;
    address public addressResolver;
    address[] public players;

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _addressResolver, address borrower) external {
        require(msg.sender == factory, 'Voyager Vault: FORBIDDEN'); // sufficient check
        addressResolver = _addressResolver;
        _setupRole(BORROWER, borrower);
    }
}

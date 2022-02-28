// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/ownership/Ownable.sol';

contract Vault is Ownable {
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
        owner = borrower;
    }
}

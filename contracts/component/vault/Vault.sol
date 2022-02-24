// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Vault {
    address public factory;
    address public player;

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _player) external {
        require(msg.sender == factory, 'Voyager: FORBIDDEN'); // sufficient check
        player = _player;
    }
}

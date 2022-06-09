// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Tus is ERC20 {
    constructor(uint256 initialSupply) ERC20("Treasure Under Sea", "TUS") {
        _mint(msg.sender, initialSupply);
    }
}

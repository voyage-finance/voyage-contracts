// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract VaultInitDiamond {
    struct Args {
        address initOwner;
    }

    function init(Args memory _args) external {}
}

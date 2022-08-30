// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VToken} from "./VToken.sol";

contract JuniorDepositToken is VToken {
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}

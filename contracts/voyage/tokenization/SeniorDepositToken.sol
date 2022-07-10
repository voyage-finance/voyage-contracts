// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LoanFacet} from "../facets/LoanFacet.sol";
import {VToken} from "./VToken.sol";

contract SeniorDepositToken is VToken {
    function totalAssets() public view override returns (uint256) {
        uint256 underlyingBalance = asset.balanceOf(address(this));
        uint256 outstandingPrincipal = LoanFacet(voyage).principalBalance(
            address(asset)
        );
        return underlyingBalance + outstandingPrincipal - totalUnbonding;
    }
}

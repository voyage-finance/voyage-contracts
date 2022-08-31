// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VToken} from "./VToken.sol";
import {LoanFacet} from "../facets/LoanFacet.sol";

contract JuniorDepositToken is VToken {
    function totalAssets() public view override returns (uint256) {
        uint256 outstandingInterest = LoanFacet(voyage).juniorInterestBalance(
            collection,
            address(asset)
        );
        return asset.balanceOf(address(this)) + outstandingInterest;
    }
}

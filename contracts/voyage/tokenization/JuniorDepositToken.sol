// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VToken} from "./VToken.sol";
import {ILoanFacet} from "../interfaces/ILoanFacet.sol";

contract JuniorDepositToken is VToken {
    function totalAssets() public view override returns (uint256) {
        uint256 outstandingInterest = ILoanFacet(voyage).juniorInterestBalance(
            collection,
            address(asset)
        );
        return asset.balanceOf(address(this)) + outstandingInterest;
    }
}

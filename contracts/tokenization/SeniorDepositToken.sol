// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LoanFacet} from "../component/facets/LoanFacet.sol";
import {VToken} from "./base/VToken.sol";

contract SeniorDepositToken is VToken {
    using SafeMath for uint256;

    function totalAssets() public view override returns (uint256) {
        uint256 underlyingBalance = asset.balanceOf(address(this));
        uint256 outstandingPrincipal = LoanFacet(voyager).principalBalance(
            address(asset)
        );
        return underlyingBalance.add(outstandingPrincipal).sub(totalUnbonding);
    }
}

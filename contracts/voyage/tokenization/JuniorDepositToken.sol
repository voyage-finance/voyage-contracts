// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {VToken} from "./VToken.sol";

contract JuniorDepositToken is VToken {
    using SafeMath for uint256;

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this)).sub(totalUnbonding);
    }
}

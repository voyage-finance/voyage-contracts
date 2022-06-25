// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {LoanFacet} from "../component/facets/LoanFacet.sol";
import {BaseDepositToken} from "./base/BaseDepositToken.sol";
import "hardhat/console.sol";

contract SeniorDepositToken is BaseDepositToken {
    using SafeMath for uint256;

    constructor(
        address _voyager,
        ERC20 _underlyingAsset,
        string memory _name,
        string memory _symbol
    ) BaseDepositToken(_voyager, _underlyingAsset, _name, _symbol) {}

    function totalAssets() public view override returns (uint256) {
        uint256 underlyingBalance = asset.balanceOf(address(this));
        console.log("underlyingBalance: %s", underlyingBalance);
        uint256 outstandingPrincipal = LoanFacet(voyager).principalBalance(
            address(asset)
        );
        console.log("outstandingPrincipal: %s", outstandingPrincipal);
        return underlyingBalance + outstandingPrincipal - totalUnbonding;
    }
}

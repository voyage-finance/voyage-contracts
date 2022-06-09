// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import {SafeMath} from "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {AddressResolver} from "../component/infra/AddressResolver.sol";
import {ILoanManager} from "../interfaces/ILoanManager.sol";
import {BaseDepositToken} from "./base/BaseDepositToken.sol";

contract JuniorDepositToken is BaseDepositToken {
    using SafeMath for uint256;

    constructor(
        AddressResolver _addressResolver,
        ERC20 _underlyingAsset,
        string memory _name,
        string memory _symbol
    ) BaseDepositToken(_addressResolver, _underlyingAsset, _name, _symbol) {}

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this)) - totalUnbonding;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LoanFacet} from "../facets/LoanFacet.sol";
import {VToken} from "./VToken.sol";
import {ERC4626, IERC4626} from "../../shared/tokenization/ERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

interface IUnbondingToken {
    function unbonding(address _user) external view returns (uint256);

    function totalUnbondingAsset() external view returns (uint256);
}

struct Unbonding {
    uint256 shares;
    uint256 maxUnderlying;
}

contract SeniorDepositToken is VToken, IUnbondingToken {
    using SafeERC20 for IERC20Metadata;

    mapping(address => Unbonding) public unbondings;

    uint256 public totalUnbonding;

    function totalAssets() public view override returns (uint256) {
        uint256 underlyingBalance = asset.balanceOf(address(this));
        uint256 outstandingPrincipal = LoanFacet(voyage).principalBalance(
            collection
        );
        uint256 outstandingInterest = LoanFacet(voyage).seniorInterestBalance(
            collection,
            address(asset)
        );
        return underlyingBalance + outstandingPrincipal;
    }

    function withdraw(
        uint256 _asset,
        address _receiver,
        address _owner
    ) public override(ERC4626) returns (uint256 shares) {
        shares = previewWithdraw(_asset); // No need to check for rounding error, previewWithdraw rounds up.
        if (msg.sender != _owner) {
            _spendAllowance(_owner, msg.sender, shares);
        }

        beforeWithdraw(_asset, shares);

        pushWithdraw(_owner, shares, _asset);

        emit Withdraw(msg.sender, _receiver, _owner, _asset, shares);
    }

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) public override(ERC4626) returns (uint256 asset) {
        if (msg.sender != _owner) {
            _spendAllowance(_owner, msg.sender, _shares);
        }
        asset = convertToAssets(_shares);
        beforeWithdraw(asset, _shares);

        pushWithdraw(_owner, _shares, asset);

        emit Withdraw(msg.sender, _receiver, _owner, asset, _shares);
    }

    function claim() public {
        uint256 maxClaimable = claimable(msg.sender);
        uint256 totalCash = asset.balanceOf(address(this));
        if (totalCash >= maxClaimable) {
            resetUnbondingPosition(msg.sender);
            asset.safeTransfer(msg.sender, maxClaimable);
        } else {
            reduceUnbondingPosition(msg.sender, totalCash);
            asset.safeTransfer(msg.sender, totalCash);
        }
    }

    function maximumClaimable(address _user) public view returns (uint256) {
        uint256 totalCash = asset.balanceOf(address(this));
        uint256 claimable = claimable(_user);
        return claimable < totalCash ? claimable : totalCash;
    }

    function claimable(address _user) public view returns (uint256) {
        uint256 maxUnderlying = unbondings[_user].maxUnderlying;
        uint256 previewRedeem = previewRedeem(unbondings[_user].shares);
        return maxUnderlying < previewRedeem ? maxUnderlying : previewRedeem;
    }

    function balanceOf(address account)
        public
        view
        override(ERC20Upgradeable)
        returns (uint256)
    {
        return super.balanceOf(account) - unbondings[account].shares;
    }

    function maxWithdraw(address owner)
        public
        view
        override(ERC4626)
        returns (uint256)
    {
        return convertToAssets(this.balanceOf(owner));
    }

    function maxRedeem(address owner)
        public
        view
        override(ERC4626)
        returns (uint256)
    {
        return this.balanceOf(owner);
    }

    /* --------------------------------- internal functions -------------------------------- */

    function pushWithdraw(
        address _user,
        uint256 _shares,
        uint256 _amount
    ) internal {
        unbondings[_user].shares += _shares;
        // unbondings[_user].maxUnderlying += convertToAssets(_shares);
        unbondings[_user].maxUnderlying += _amount;
        totalUnbonding += _shares;
    }

    function resetUnbondingPosition(address _user) internal {
        _burn(_user, unbondings[_user].shares);
        totalUnbonding -= unbondings[_user].shares;
        unbondings[_user].shares = 0;
        unbondings[_user].maxUnderlying = 0;
    }

    function reduceUnbondingPosition(address _user, uint256 _amount) internal {
        uint256 shares = previewWithdraw(_amount);
        _burn(_user, shares);
        unbondings[_user].shares -= shares;
        totalUnbonding -= shares;
        unbondings[_user].maxUnderlying -= _amount;
    }

    /* --------------------------------- external functions -------------------------------- */

    function totalUnbondingAsset() external view returns (uint256) {
        return previewWithdraw(totalUnbonding);
    }

    function unbonding(address _user) external view returns (uint256) {
        return convertToAssets(unbondings[_user].shares);
    }
}

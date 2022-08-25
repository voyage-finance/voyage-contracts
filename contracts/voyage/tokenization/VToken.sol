// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626, IERC4626} from "../../shared/tokenization/ERC4626.sol";
import {IVToken} from "../interfaces/IVToken.sol";

struct Unbonding {
    uint256 shares;
    uint256 maxUnderlying;
}

abstract contract VToken is Initializable, ERC4626, IVToken {
    using SafeERC20 for IERC20Metadata;

    address internal voyage;
    mapping(address => Unbonding) public unbondings;

    uint256 public totalUnbonding;

    uint256 public cooldown = 7 days;

    event Claim(address receiver, uint256 amount, uint256 shares);

    modifier onlyAdmin() {
        require(_msgSender() == voyage, "Not admin");
        _;
    }

    function initialize(address _voyage, address _asset) public initializer {
        IERC20Metadata underlying = IERC20Metadata(_asset);
        voyage = _voyage;
        __ERC20_init(underlying.name(), underlying.symbol());
        __ERC20Permit_init(underlying.name());
        __ERC4626_init(underlying);
    }

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    ) public override(ERC4626, IERC4626) returns (uint256 shares) {
        shares = previewWithdraw(_amount); // No need to check for rounding error, previewWithdraw rounds up.
        if (msg.sender != _owner) {
            _spendAllowance(_owner, msg.sender, shares);
        }

        beforeWithdraw(_amount, shares);

        _burn(_owner, shares);
        pushWithdraw(_owner, shares);

        emit Withdraw(msg.sender, _receiver, _owner, _amount, shares);
    }

    function transferUnderlyingTo(address _target, uint256 _amount)
        public
        onlyAdmin
    {
        asset.safeTransfer(_target, _amount);
    }

    function totalUnbondingAsset() public view returns (uint256) {
        return convertToAssets(totalUnbonding);
    }

    function pushWithdraw(address _user, uint256 _shares) internal {
        unbondings[_user].shares += _shares;
        unbondings[_user].maxUnderlying += convertToAssets(_shares);
        totalUnbonding += _shares;
    }

    function resetUnbondingPosition(address _user) internal {
        unbondings[_user].shares = 0;
        unbondings[_user].maxUnderlying = 0;
    }

    function reduceUnbondingPosition(uint256 _shares, uint256 _asset) internal {
        if (_shares > unbondings[msg.sender].shares) {
            unbondings[msg.sender].shares == 0;
            unbondings[msg.sender].maxUnderlying = 0;
            return;
        }
        unbondings[msg.sender].maxUnderlying -= _asset;
        unbondings[msg.sender].shares -= _shares;
    }

    function claim() external {
        uint256 maxClaimable = unbondings[msg.sender].maxUnderlying;
        uint256 availableLiquidity = asset.balanceOf(address(this));
        uint256 transferredShares;
        uint256 transferredAsset;
        if (availableLiquidity > maxClaimable) {
            transferredAsset = maxClaimable;
            transferredShares = unbondings[msg.sender].shares;
            resetUnbondingPosition(msg.sender);
        } else {
            transferredAsset = availableLiquidity;
            uint256 shares = convertToShares(availableLiquidity);
            reduceUnbondingPosition(shares, transferredAsset);
            transferredShares = shares;
        }
        totalUnbonding -= transferredShares;
        asset.safeTransfer(msg.sender, transferredAsset);
        emit Claim(msg.sender, transferredAsset, transferredShares);
    }

    function unbonding(address _user) external view returns (uint256) {
        return convertToAssets(unbondings[_user].shares);
    }

    function maximumClaimable(address _user) external view returns (uint256) {
        uint256 underlyingUnbonding = unbondings[_user].maxUnderlying;
        uint256 underlyingNow = convertToAssets(unbondings[_user].shares);
        return
            underlyingUnbonding < underlyingNow
                ? underlyingUnbonding
                : underlyingNow;
    }
}

/* --------------------------------- errors -------------------------------- */
error InsufficientLiquidity();
error InvalidIndex();
error CollDownError();

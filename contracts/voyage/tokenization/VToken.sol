// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626, IERC4626} from "../../shared/tokenization/ERC4626.sol";
import {IVToken} from "../interfaces/IVToken.sol";

abstract contract VToken is Initializable, ERC4626, IVToken {
    using SafeERC20 for IERC20Metadata;

    address internal voyage;
    // user address => shares
    mapping(address => uint256) public withdrawalbleShare;
    mapping(address => uint256) public withdrawaleUnderlying;

    uint256 public totalUnbonding;

    uint256 public cooldown = 7 days;

    event Claim(address receiver, uint256 amount);

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
        withdrawalbleShare[_user] += _shares;
        withdrawaleUnderlying[_user] += convertToAssets(_shares);
        totalUnbonding += _shares;
    }

    function reset(address _user) internal {
        withdrawaleUnderlying[_user] = 0;
        withdrawalbleShare[_user] = 0;
    }

    function subtract(uint256 _shares, uint256 _asset) internal {
        withdrawaleUnderlying[msg.sender] -= _asset;
        withdrawalbleShare[msg.sender] -= _shares;
    }

    function claim() external {
        if (withdrawalbleShare[msg.sender] == 0) {
            withdrawaleUnderlying[msg.sender] = 0;
            return;
        }

        uint256 ownedAsset = withdrawaleUnderlying[msg.sender];
        uint256 totalAsset = asset.balanceOf(address(this));
        uint256 transferredShares;
        uint256 transferredAsset;
        if (totalAsset > ownedAsset) {
            transferredAsset = ownedAsset;
            transferredShares = withdrawalbleShare[msg.sender];
            reset(msg.sender);
        } else {
            transferredAsset = totalAsset;
            uint256 shares = convertToShares(totalAsset);
            subtract(shares, transferredAsset);
            transferredShares = shares;
        }
        totalUnbonding -= transferredShares;
        asset.safeTransfer(msg.sender, transferredAsset);
    }

    function unbonding(address _user) external view returns (uint256) {
        return convertToAssets(withdrawalbleShare[_user]);
    }

    function maximumClaimable(address _user) external view returns (uint256) {
        uint256 underlyingUnbonding = withdrawaleUnderlying[_user];
        uint256 underlyingNow = convertToAssets(withdrawalbleShare[_user]);
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

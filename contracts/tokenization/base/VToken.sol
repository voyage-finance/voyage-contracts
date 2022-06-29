// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {ERC4626, IERC4626} from "./ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVToken} from "../../interfaces/IVToken.sol";

abstract contract VToken is Initializable, ERC4626, IVToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    address internal voyager;
    // user address => timestamp => amount
    mapping(address => mapping(uint256 => uint256)) private withdrawals;

    // user address => timestamp array
    mapping(address => uint256[]) private pendingTimestamp;

    uint256 public totalUnbonding;

    uint256 public cooldown = 7 days;

    event Claim(address receiver, uint256 amount);

    modifier onlyAdmin() {
        require(
            _msgSender() == voyager,
            Errors.CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL
        );
        _;
    }

    function initialize(address _voyager, address _asset) public initializer {
        IERC20Metadata underlying = IERC20Metadata(_asset);
        voyager = _voyager;
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
        pushWithdraw(_owner, _amount);

        emit Withdraw(msg.sender, _receiver, _owner, _amount, shares);
    }

    function claim(uint256 _index) public {
        uint256 amount = popWithdraw(msg.sender, _index);
        require(
            asset.balanceOf(address(this)) >= amount,
            "Insufficient liquidity available"
        );
        asset.safeTransfer(msg.sender, amount);
    }

    function transferUnderlyingTo(address _target, uint256 _amount)
        public
        onlyAdmin
    {
        asset.safeTransfer(_target, _amount);
    }

    function pushWithdraw(address _user, uint256 _amount) internal {
        require(withdrawals[_user][block.timestamp] == 0, "invalid withdraw");
        withdrawals[_user][block.timestamp] = _amount;
        pendingTimestamp[_user].push(block.timestamp);
        totalUnbonding += _amount;
    }

    function popWithdraw(address _user, uint256 _index)
        internal
        returns (uint256)
    {
        uint256[] storage times = pendingTimestamp[_user];
        require(_index < times.length, "invalid index");
        uint256 ts = times[_index];
        require(block.timestamp - ts > cooldown, "cool down error");

        uint256 last = times[times.length - 1];
        times[_index] = last;
        times.pop();

        uint256 withdrawable = withdrawals[_user][ts];
        delete withdrawals[_user][ts];
        totalUnbonding -= withdrawable;
        return withdrawable;
    }

    function unbonding(address _user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory times = pendingTimestamp[_user];
        uint256[] memory amounts = new uint256[](times.length);

        for (uint256 i = 0; i < times.length; i++) {
            amounts[i] = withdrawals[_user][times[i]];
        }

        return (times, amounts);
    }
}

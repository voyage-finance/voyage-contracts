// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IVToken} from "../../interfaces/IVToken.sol";
import {AddressResolver} from "../../component/infra/AddressResolver.sol";

abstract contract BaseDepositToken is Context, IVToken {
    using SafeMath for uint256;
    using SafeTransferLib for ERC20;

    address internal immutable voyager;
    // user address => timestamp => amount
    mapping(address => mapping(uint256 => uint256)) private withdrawals;

    // user address => timestamp array
    mapping(address => uint256[]) private pendingTimestamp;

    uint256 public override totalUnbonding;

    uint256 public cooldown = 7 days;

    event Claim(address receiver, uint256 amount);

    modifier onlyAdmin() {
        require(
            _msgSender() == voyager,
            Errors.CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL
        );
        _;
    }

    constructor(
        address _voyager,
        ERC20 _underlyingAsset,
        string memory _name,
        string memory _symbol
    ) IVToken(_underlyingAsset, _name, _symbol) {
        voyager = _voyager;
    }

    function withdraw(
        uint256 _amount,
        address _receiver,
        address _owner
    ) public override returns (uint256 shares) {
        shares = previewWithdraw(_amount); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(_amount, shares);

        _burn(_owner, shares);
        pushWithdraw(_owner, _amount);

        emit Withdraw(msg.sender, _receiver, _owner, _amount, shares);
    }

    function claim(uint256 _index) public override {
        uint256 amount = popWithdraw(msg.sender, _index);
        require(
            asset.balanceOf(address(this)) >= amount,
            "Insufficient liquidity available"
        );
        asset.safeTransfer(msg.sender, amount);
    }

    function transferUnderlyingTo(address _target, uint256 _amount)
        public
        override
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
        override
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

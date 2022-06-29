// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CreditEscrow is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    function transferUnderlyingTo(
        address _asset,
        address _target,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_asset).safeTransfer(_target, _amount);
    }
}

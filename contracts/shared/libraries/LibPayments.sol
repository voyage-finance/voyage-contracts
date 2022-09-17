// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibAppStorage} from "../../voyage/libraries/LibAppStorage.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";

library LibPayments {
    using SafeERC20 for IERC20;

    function unwrapWETH9(uint256 amountMinimum, address recipient) internal {
        uint256 balanceWETH9 = LibAppStorage.ds().WETH9.balanceOf(
            address(this)
        );
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            LibAppStorage.ds().WETH9.withdraw(balanceWETH9);
            SafeTransferLib.safeTransferETH(recipient, balanceWETH9);
        }
    }

    function wrapWETH9() internal {
        if (address(this).balance > 0)
            LibAppStorage.ds().WETH9.deposit{value: address(this).balance}(); // wrap everything
    }

    function sweepToken(
        IERC20 token,
        uint256 amountMinimum,
        address recipient
    ) internal {
        uint256 balanceToken = token.balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            token.safeTransfer(recipient, balanceToken);
        }
    }

    function refundETH() internal {
        if (address(this).balance > 0) {
            SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
        }
    }

    function pullToken(
        IERC20 token,
        uint256 amount,
        address from,
        address recipient
    ) internal {
        token.safeTransferFrom(from, recipient, amount);
    }

    function approve(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        token.safeApprove(to, amount);
    }
}

abstract contract IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable virtual;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external virtual;
}

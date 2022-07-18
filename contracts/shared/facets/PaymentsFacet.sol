// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {PeripheryPayments} from "../util/PeripheryPayments.sol";
import {Multicall} from "../util/Multicall.sol";
import {SelfPermit} from "../util/SelfPermit.sol";
import {LibAppStorage} from "../../voyage/libraries/LibAppStorage.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentsFacet is PeripheryPayments, Multicall, SelfPermit {
    using SafeTransferLib for IERC20;

    function unwrapWETH9(uint256 amountMinimum, address recipient)
        public
        payable
    {
        uint256 balanceWETH9 = LibAppStorage.diamondStorage().WETH9.balanceOf(
            address(this)
        );
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            LibAppStorage.diamondStorage().WETH9.withdraw(balanceWETH9);
            SafeTransferLib.safeTransferETH(recipient, balanceWETH9);
        }
    }

    function wrapWETH9() public payable {
        if (address(this).balance > 0)
            LibAppStorage.diamondStorage().WETH9.deposit{
                value: address(this).balance
            }(); // wrap everything
    }

    function sweepToken(
        IERC20 token,
        uint256 amountMinimum,
        address recipient
    ) public payable {
        uint256 balanceToken = token.balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            token.safeTransfer(recipient, balanceToken);
        }
    }

    function refundETH() external payable {
        if (address(this).balance > 0) {
            SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
        }
    }
}

abstract contract IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable virtual;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external virtual;
}

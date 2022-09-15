// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibPeripheryPayments} from "../libraries/LibPeripheryPayments.sol";
import {Multicall} from "../util/Multicall.sol";
import {SelfPermit} from "../util/SelfPermit.sol";
import {LibAppStorage} from "../../voyage/libraries/LibAppStorage.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PaymentsFacet is Multicall, SelfPermit {
    using SafeERC20 for IERC20;

    modifier auth() {
        require(msg.sender == address(this), "Unauthorised");
        _;
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient)
        public
        payable
        auth
    {
        uint256 balanceWETH9 = LibAppStorage.ds().WETH9.balanceOf(
            address(this)
        );
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            LibAppStorage.ds().WETH9.withdraw(balanceWETH9);
            SafeTransferLib.safeTransferETH(recipient, balanceWETH9);
        }
    }

    function wrapWETH9() public payable auth {
        if (address(this).balance > 0)
            LibAppStorage.ds().WETH9.deposit{value: address(this).balance}(); // wrap everything
    }

    function sweepToken(
        IERC20 token,
        uint256 amountMinimum,
        address recipient
    ) public payable auth {
        uint256 balanceToken = token.balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            token.safeTransfer(recipient, balanceToken);
        }
    }

    function refundETH() external payable auth {
        if (address(this).balance > 0) {
            SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
        }
    }

    function pullToken(
        IERC20 token,
        uint256 amount,
        address from,
        address recipient
    ) external auth {
        LibPeripheryPayments.pullToken(token, amount, from, recipient);
    }
}

abstract contract IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable virtual;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external virtual;
}

error Unauthorised();

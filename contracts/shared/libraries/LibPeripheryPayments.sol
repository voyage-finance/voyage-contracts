// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Depositor
/// @author Voyage Finance
/// @notice Forwards calls to ERC-4626 compliant Vaults, but with the actual depositor appended to the encoded call data.
/// @dev This does not work if the receiving contract does not implement ERC-4626!
library LibPeripheryPayments {
    using SafeERC20 for IERC20;

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

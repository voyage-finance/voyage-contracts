// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;
import {ERC20, SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/// @title Depositor
/// @author Voyage Finance
/// @notice Forwards calls to ERC-4626 compliant Vaults, but with the actual depositor appended to the encoded call data.
/// @dev This does not work if the receiving contract does not implement ERC-4626!
abstract contract PeripheryPayments {
    using SafeTransferLib for *;

    function pullToken(
        ERC20 token,
        uint256 amount,
        address from,
        address recipient
    ) public payable {
        token.safeTransferFrom(from, recipient, amount);
    }

    function approve(
        ERC20 token,
        address to,
        uint256 amount
    ) public payable {
        token.safeApprove(to, amount);
    }
}

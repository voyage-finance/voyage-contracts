// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import {Context} from 'openzeppelin-solidity/contracts/utils/Context.sol';

/// @title DepositContext
/// @author Voyage Finance
/// @notice Provides _depositor() for forwarded calls. Different to _msgSender().
/// @dev Callers of contracts inheriting DepositContext are responsible for calling _setDepositor().
abstract contract DepositContext is Context {
    bytes4 internal immutable ERC4626_DEPOSIT_SELECTOR =
        bytes4(keccak256('deposit(uint256,address)'));

    // 4 (selector) + 32 (uint256) +  32 (address, padded) + 20 (address, packed)
    uint8 internal immutable CALLDATASIZE = 88;

    function _depositor() internal view returns (address depositor) {
        if (!isForwardedDeposit()) {
            return _msgSender();
        }

        assembly {
            // load the last 20 bytes of calldata
            // shift right by 12 bytes (96 bits) to get rid of padding
            depositor := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    function isForwardedDeposit() internal view returns (bool) {
        if (msg.data.length != CALLDATASIZE) {
            return false;
        }

        bytes4 selector = bytes4(msg.data[0:4]);
        if (selector != ERC4626_DEPOSIT_SELECTOR) {
            return false;
        }

        return true;
    }
}

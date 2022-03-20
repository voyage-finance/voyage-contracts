// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

/**
 * @title Errors library
 * @author Voyager
 * @notice Defines the error messages emitted by the different contracts of the Voyager protocol
 * @dev Error messages prefix glossary:
 *  - LM = LiquidityManager
 *  - CT = Common errors between tokens
 */
library Errors {
    string public constant CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL = '20';
    string public constant LM_NOT_CONTRACT = '60';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

/**
 * @title Errors library
 * @author Voyager
 * @notice Defines the error messages emitted by the different contracts of the Voyager protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - LM = LiquidityManager
 *  - CT = Common errors between tokens
 *  - RL = ReserveLogic
 */
library Errors {
    string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
    string public constant CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL = '20';
    string public constant CT_INVALID_MINT_AMOUNT = '21';
    string public constant CT_INVALID_BURN_AMOUNT = '22';
    string public constant LM_NOT_CONTRACT = '60';
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = '80'; //  Liquidity rate overflows uint128
    string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '81'; //  Stable borrow rate overflows uint128
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

/**
 * @title Errors library
 * @author Voyage
 * @notice Defines the error messages emitted by the different contracts of the Voyage protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - LM = LiquidityManager
 *  - LOM = LoanManager
 *  - CT = Common errors between tokens
 *  - RL = ReserveLogic
 */
library Errors {
    string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
    string public constant CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL = "20";
    string public constant CT_CALLER_MUST_BE_LOAN_MANAGER = "21";
    string public constant CT_INVALID_MINT_AMOUNT = "21";
    string public constant CT_INVALID_BURN_AMOUNT = "22";
    string public constant LM_NOT_CONTRACT = "60";
    string public constant LP_IS_PAUSED = "61"; // 'Pool is paused'
    string public constant LOM_RESERVE_NOT_SUFFICIENT = "70";
    string public constant LOM_CREDIT_NOT_SUFFICIENT = "71";
    string public constant LOM_HEALTH_RISK_BELOW_ONE = "72";
    string public constant LOM_NOT_VAULT_OWNER = "73";
    string public constant LOM_INVALID_AMOUNT = "74";
    string public constant LOM_INVALID_DEBT = "75";
    string public constant LOM_INVALID_LIQUIDATE = "76";
    string public constant LOM_INSUFFICIENT_JUNIOR = "77";
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "80"; //  Liquidity rate overflows uint128
    string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "81"; //  Stable borrow rate overflows uint128
}
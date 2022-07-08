// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibReserveConfiguration} from "./LibReserveConfiguration.sol";
import {ReserveConfigurationMap, ReserveData} from "./LibAppStorage.sol";

library ValidationLogic {
    using LibReserveConfiguration for ReserveConfigurationMap;

    /**
     * @dev Validates a deposit token
     * @param reserve The reserve object on which the user is depositing
     * @param amount The amount to be deposited
     **/
    function validateDeposit(ReserveData storage reserve, uint256 amount)
        internal
        view
    {
        (bool isActive, bool isFrozen, ) = reserve.configuration.getFlags();
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (!isActive) {
            revert ReserveNotActive();
        }
        if (isFrozen) {
            revert ReserveFrozen();
        }
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidAmount();
error ReserveNotActive();
error ReserveFrozen();

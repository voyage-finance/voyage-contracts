// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Voyage
 * @notice Implements the bitmap logic to handle the reserve configuration, inspired by Aave
 **/
library ReserveConfiguration {
    uint256 constant LIQUIDATE_BONUS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant DECIMAL_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFFF; // prettier-ignore
    uint256 constant ACTIVE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFF; // prettier-ignore
    uint256 constant FROZEN_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFF; // prettier-ignore
    uint256 constant BORROWING_ENABLE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFF; // prettier-ignore
    uint256 constant RESERVED_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF87FFFFFF; // prettier-ignore
    uint256 constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFA0007FFFFFFF; // prettier-ignore
    uint256 constant LOCKUP_PERIOD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80007FFFFFFFFFFF; // prettier-ignore

    /**
     * Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled
     **/
    function getFlags(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_ENABLE_MASK) != 0
        );
    }
}

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

    uint256 constant DECIMAL_MASK_BIT_POSITION = 16;
    uint256 constant ACTIVE_MASK_BIT_POSITION = 24;
    uint256 constant FROZEN_MASK_BIT_POSITION = 25;
    uint256 constant BORROWING_ENABLE_MASK_POSITION = 26;
    uint256 constant RESERVED_MASK_BIT_POSITION = 26;
    uint256 constant RESERVE_FACTOR_MASK_BIT_POSITION = 31;
    uint256 constant LOCKUP_PERIOD_MASK_BIT_POSITION = 47;

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

    /**
     * @dev Gets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(
        DataTypes.ReserveConfigurationMap memory self,
        bool active
    ) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << ACTIVE_MASK_BIT_POSITION);
    }
}

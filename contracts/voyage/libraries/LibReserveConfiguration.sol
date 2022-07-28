// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReserveData, ReserveConfigurationMap, AppStorage, LibAppStorage} from "./LibAppStorage.sol";

/**
 * @title ReserveConfiguration library
 * @author Voyage
 * @notice Implements the bitmap logic to handle the reserve configuration, inspired by Aave
 **/
library LibReserveConfiguration {
    uint256 constant internal LIQUIDATION_BONUS_MASK =  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant internal DECIMAL_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFF; // prettier-ignore
    uint256 constant internal ACTIVE_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFF; // prettier-ignore
    uint256 constant internal FROZEN_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFF; // prettier-ignore
    uint256 constant internal BORROWING_ENABLE_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFF; // prettier-ignore
    uint256 constant internal MIN_MARGIN_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFF; // prettier-ignore
    uint256 constant internal MAX_MARGIN_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant internal MARGIN_REQUIREMENT_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant internal INCOME_RATIO_MASK =       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant internal LOAN_INTERVAL_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant internal LOAN_TERM_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant internal GRACE_PERIOD_MASK =       0xFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    uint256 internal constant DECIMAL_MASK_BIT_POSITION = 16;
    uint256 internal constant ACTIVE_MASK_BIT_POSITION = 24;
    uint256 internal constant FROZEN_MASK_BIT_POSITION = 25;
    uint256 internal constant BORROWING_ENABLE_MASK_POSITION = 26;
    /// @dev bit 27 reserved
    uint256 internal constant MIN_MARGIN_MASK_BIT_POSITION = 28;
    uint256 internal constant MAX_MARGIN_MASK_BIT_POSITION = 64;
    uint256 internal constant MARGIN_REQUIREMENT_MASK_BIT_POSITION = 100;
    uint256 internal constant INCOME_RATIO_MASK_BIT_POSITION = 116;
    uint256 internal constant LOAN_INTERVAL_MASK_BIT_POSITION = 132;
    uint256 internal constant LOAN_TERM_MASK_BIT_POSITION = 140;
    uint256 internal constant GRACE_PERIOD_MASK_BIT_POSITION = 156;

    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535; // percentage
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_MIN_MARGIN = 68719476735; // in **whole** tokens, mul by decimals before use
    uint256 internal constant MAX_VALID_MAX_MARGIN = 68719476735; // in **whole** tokens, mul by decimals before use
    uint256 internal constant MAX_VALID_MARGIN_REQUIREMENT = 65535; // percentage, max 100%/10000 bps
    uint256 internal constant MAX_VALID_INCOME_RATIO = 10000; // percentage, max 100%/10000 bps
    uint256 internal constant MAX_VALID_LOAN_INTERVAL = 255; // days
    uint256 internal constant MAX_VALID_LOAN_TERM = 65535; // days
    uint256 internal constant MAX_VALID_GRACE_PERIOD = 255; // days

    error InvalidLiquidationBonus();
    error InvalidDecimals();
    error InvalidMinMargin();
    error InvalidMaxMargin();
    error InvalidMarginRequirement();
    error InvalidIncomeRatio();
    error InvalidLoanInterval();
    error InvalidLoanTerm();
    error InvalidGracePeriod();

    event LiquidationConfigurationUpdated(
        address indexed _asset,
        uint256 _liquidationBonus
    );
    event MarginParametersUpdated(
        address indexed _asset,
        uint256 _min,
        uint256 _max,
        uint256 _marginRequirement
    );

    /* --------------------------- receiver functions --------------------------- */

    /**
     * Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled
     **/
    function getFlags(ReserveConfigurationMap memory self)
        internal
        pure
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

    function setLiquidationBonus(
        ReserveConfigurationMap memory self,
        uint256 liquidationBonus
    ) internal pure {
        if (liquidationBonus > MAX_VALID_LIQUIDATION_BONUS) {
            revert InvalidLiquidationBonus();
        }
        self.data = (self.data & LIQUIDATION_BONUS_MASK) | liquidationBonus;
    }

    function getLiquidationBonus(ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return self.data & ~LIQUIDATION_BONUS_MASK;
    }

    function setDecimals(ReserveConfigurationMap memory self, uint256 _decimals)
        internal
        pure
    {
        if (_decimals > MAX_VALID_DECIMALS) {
            revert InvalidDecimals();
        }
        self.data =
            (self.data & DECIMAL_MASK) |
            (_decimals << DECIMAL_MASK_BIT_POSITION);
    }

    function getDecimals(ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~DECIMAL_MASK) >> DECIMAL_MASK_BIT_POSITION;
    }

    /**
     * @dev Gets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(ReserveConfigurationMap memory self, bool active)
        internal
        pure
    {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << ACTIVE_MASK_BIT_POSITION);
    }

    function getActive(ReserveConfigurationMap storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    function setMinMargin(ReserveConfigurationMap memory self, uint256 num)
        internal
        pure
    {
        if (num > MAX_VALID_MIN_MARGIN) {
            revert InvalidMinMargin();
        }
        self.data =
            (self.data & MIN_MARGIN_MASK) |
            (num << MIN_MARGIN_MASK_BIT_POSITION);
    }

    function getMinMargin(ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~MIN_MARGIN_MASK) >> MIN_MARGIN_MASK_BIT_POSITION;
    }

    function setMaxMargin(ReserveConfigurationMap memory self, uint256 num)
        internal
        pure
    {
        if (num > MAX_VALID_MAX_MARGIN) {
            revert InvalidMaxMargin();
        }
        self.data =
            (self.data & MAX_MARGIN_MASK) |
            (num << MAX_MARGIN_MASK_BIT_POSITION);
    }

    function getMaxMargin(ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~MAX_MARGIN_MASK) >> MAX_MARGIN_MASK_BIT_POSITION;
    }

    function setIncomeRatio(ReserveConfigurationMap memory self, uint256 ratio)
        internal
        pure
    {
        if (ratio > MAX_VALID_INCOME_RATIO) {
            revert InvalidIncomeRatio();
        }

        self.data =
            (self.data & INCOME_RATIO_MASK) |
            (ratio << INCOME_RATIO_MASK_BIT_POSITION);
    }

    function getIncomeRatio(ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~INCOME_RATIO_MASK) >> INCOME_RATIO_MASK_BIT_POSITION;
    }

    function setLoanInterval(
        ReserveConfigurationMap memory self,
        uint256 interval
    ) internal pure {
        if (interval > MAX_VALID_LOAN_INTERVAL) {
            revert InvalidLoanInterval();
        }
        self.data =
            (self.data & LOAN_INTERVAL_MASK) |
            (interval << LOAN_INTERVAL_MASK_BIT_POSITION);
    }

    function setLoanTerm(ReserveConfigurationMap memory self, uint256 term)
        internal
        pure
    {
        if (term > MAX_VALID_LOAN_TERM) {
            revert InvalidLoanTerm();
        }
        self.data =
            (self.data & LOAN_TERM_MASK) |
            (term << LOAN_TERM_MASK_BIT_POSITION);
    }

    function setMarginRequirement(
        ReserveConfigurationMap memory self,
        uint256 num
    ) internal pure {
        if (num > MAX_VALID_MARGIN_REQUIREMENT) {
            revert InvalidMarginRequirement();
        }

        self.data =
            (self.data & MARGIN_REQUIREMENT_MASK) |
            (num << MARGIN_REQUIREMENT_MASK_BIT_POSITION);
    }

    function setGracePeriod(
        ReserveConfigurationMap memory self,
        uint256 numDays
    ) internal pure {
        if (numDays > MAX_VALID_GRACE_PERIOD) {
            revert InvalidGracePeriod();
        }
        self.data =
            (self.data & GRACE_PERIOD_MASK) |
            (numDays << GRACE_PERIOD_MASK_BIT_POSITION);
    }

    function getMarginParams(ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 localData = self.data;
        return (
            (localData & ~MIN_MARGIN_MASK) >> MIN_MARGIN_MASK_BIT_POSITION,
            (localData & ~MAX_MARGIN_MASK) >> MAX_MARGIN_MASK_BIT_POSITION,
            (localData & ~MARGIN_REQUIREMENT_MASK) >>
                MARGIN_REQUIREMENT_MASK_BIT_POSITION
        );
    }

    function validateMarginParams(
        uint256 _min,
        uint256 _max,
        uint256 _marginRequirement
    ) internal pure returns (bool) {
        if (_min > _max || _marginRequirement == 0) {
            return false;
        }
        return true;
    }

    function getBorrowParams(ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 localData = self.data;
        return (
            (localData & ~LOAN_INTERVAL_MASK) >>
                LOAN_INTERVAL_MASK_BIT_POSITION,
            (localData & ~LOAN_TERM_MASK) >> LOAN_TERM_MASK_BIT_POSITION
        );
    }

    function getLiquidationParams(ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 localData = self.data;
        return (
            (localData & ~LIQUIDATION_BONUS_MASK),
            (localData & ~MARGIN_REQUIREMENT_MASK) >>
                MARGIN_REQUIREMENT_MASK_BIT_POSITION,
            (localData & ~GRACE_PERIOD_MASK) >> GRACE_PERIOD_MASK_BIT_POSITION
        );
    }

    function getConfiguration(address _collection)
        internal
        view
        returns (ReserveConfigurationMap memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._reserveData[_collection].configuration;
    }

    function saveConfiguration(
        address _collection,
        ReserveConfigurationMap memory _conf
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s._reserveData[_collection].configuration = _conf;
    }
}

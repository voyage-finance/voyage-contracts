// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

library DataTypes {
    enum Tranche {
        JUNIOR,
        SENIOR
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        // for calculating overall interested accumulated
        // then split it into two indexs base on two allocations
        uint256 currentOverallLiquidityRate;
        // Expressed in ray
        uint256 currentSeniorIncomeAllocation;
        // Expressed in ray
        uint256 currentJuniorIncomeAllocation;
        uint256 currentJuniorLiquidityIndex;
        uint256 currentSeniorLiquidityIndex;
        uint256 totalBorrows;
        uint256 currentBorrowRate;
        // Expressed in ray
        uint256 securityRequirement;
        //the decimals of the reserve asset
        uint256 decimals;
        address interestRateStrategyAddress;
        address juniorDepositTokenAddress;
        address seniorDepositTokenAddress;
        uint40 lastUpdateTimestamp;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: Liq. bonus
        //bit 16-23: Decimals
        //bit 24: Reserve is active
        //bit 25: reserve is frozen
        //bit 26: borrowing is enabled
        //bit 27-30: reserved
        //bit 31-46: reserve factor
        //bit 47-62: lock up period in seconds
        uint256 data;
    }
}

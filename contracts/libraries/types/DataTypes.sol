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
        uint256 juniorLiquidityIndex;
        uint256 seniorLiquidityIndex;
        uint256 totalBorrows;
        uint256 currentBorrowRate;
        // Expressed in ray
        uint256 securityRequirement;
        //the decimals of the reserve asset
        uint256 decimals;
        address interestRateStrategyAddress;
        address juniorDepositTokenAddress;
        address seniorDepositTokenAddress;
        address stableDebtAddress;
        uint40 juniorLastUpdateTimestamp;
        uint40 seniorLastUpdateTimestamp;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: Liquidate bonus
        //bit 16-23: Decimals
        //bit 24: Reserve is active
        //bit 25: reserve is frozen
        //bit 26: borrowing is enabled
        //bit 27-30: reserved
        //bit 31-46: reserve factor
        //bit 47-62: lock up period in seconds
        uint256 data;
    }

    struct VaultData {
        uint256 drawDownNumber;
        uint256 totalDebt;
        mapping(uint256 => DrawDown) drawDowns;
        mapping(uint256 => Repayment) repayments;
    }

    struct DrawDown {
        uint256 amount;
        uint256 tenure;
        uint256 timestamp;
    }

    struct Repayment {
        uint256 totalPaid;
        uint256 tenurePassed;
        // tenure => amount
        // todo wrapper this in the future
        mapping(uint256 => uint256) repayment;
    }
}

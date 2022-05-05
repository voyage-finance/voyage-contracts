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
        uint256 juniorDepositAmount;
        uint256 seniorDepositAmount;
        uint256 currentBorrowRate;
        // Expressed in ray
        uint256 securityRequirement;
        //the decimals of the reserve asset
        uint256 decimals;
        address interestRateStrategyAddress;
        address healthStrategyAddress;
        address juniorDepositTokenAddress;
        address seniorDepositTokenAddress;
        address stableDebtAddress;
        uint40 juniorLastUpdateTimestamp;
        uint40 seniorLastUpdateTimestamp;
        uint256 optimalTrancheRatio;
        uint256 optimalIncomeRatio;
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

    struct VaultConfig {
        uint256 minSecurityDeposit;
        uint256 maxSecurityDeposit;
        uint256 securityDepositRequirement;
    }

    struct FungibleTokenData {
        string symbol;
        address tokenAddress;
    }

    struct BorrowData {
        uint256 drawDownNumber;
        uint256 totalDebt;
        mapping(uint256 => DrawDown) drawDowns;
        mapping(uint256 => Repayment) repayments;
    }

    struct DrawDown {
        uint256 amount;
        uint256 tenure;
        uint40 timestamp;
        uint256 borrowRate;
        Repayment repayment;
    }

    struct Repayment {
        uint256 totalPaid;
        // tenure => amount
        // todo wrapper this in the future
        mapping(uint256 => uint256) repayment;
    }

    // tmp struct to avoid stack too long

    struct DepositAndDebt {
        uint256 juniorDepositAmount;
        uint256 seniorDepositAmount;
        uint256 totalDebt;
        uint256 avgStableRate;
    }

    struct HealthRiskParameter {
        uint256 securityDeposit;
        uint256 currentBorrowRate;
        uint256 compoundedDebt;
        uint256 grossAssetValue;
        uint256 aggregateOptimalRepaymentRate;
        uint256 aggregateActualRepaymentRate;
    }

    struct PoolConfiguration {
        uint256 securityRequirement;
        uint256 minSecurity;
        uint256 maxSecurity;
        uint256 loanTenure;
        uint256 optimalTrancheRatio;
        uint256 optimalIncomeRatio;
        bool isActive;
    }

    struct PoolData {
        uint256 totalLiquidity;
        uint256 juniorLiquidity;
        uint256 seniorLiquidity;
        uint256 juniorLiquidityRate;
        uint256 seniorLiquidityRate;
        uint256 totalDebt;
        uint256 borrowRate;
        uint256 trancheRatio;
        uint256 decimals;
    }

    struct VaultData {
        uint256 borrowRate;
        uint256 totalDebt;
        uint256 totalSecurityDeposit;
        uint256 withdrawableSecurityDeposit;
        uint256 creditLimit;
        uint256 spendableBalance;
        uint256 gav;
        uint256 ltv;
        uint256 optimalAggregateRepaymentRate;
        uint256 actualAggregateRepaymentRate;
        uint256 healthFactor;
    }

    struct UserPoolData {
        uint256 juniorTrancheBalance;
        uint256 withdrawableJuniorTrancheBalance;
        uint256 seniorTrancheBalance;
        uint256 withdrawableSeniorTrancheBalance;
    }
}

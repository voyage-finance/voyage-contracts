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
        uint256 currentJuniorLiquidityRate;
        uint256 currentSeniorLiquidityRate;
        uint256 juniorLiquidityIndex;
        uint256 seniorLiquidityIndex;
        uint256 currentBorrowRate;
        // Expressed in ray
        uint256 securityRequirement;
        //the decimals of the reserve asset
        uint256 decimals;
        address interestRateStrategyAddress;
        address healthStrategyAddress;
        address juniorDepositTokenAddress;
        address seniorDepositTokenAddress;
        address debtTokenAddress;
        uint40 juniorLastUpdateTimestamp;
        uint40 seniorLastUpdateTimestamp;
        uint256 optimalTrancheRatio;
        uint256 currentIncomeRatio;
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
        uint256 mapSize;
        mapping(uint256 => DrawDown) drawDowns;
    }

    struct DrawDown {
        // remaining amount todo @xiaohuo maybe add initial amount
        uint256 amount;
        // the total intended length of the loan in seconds - e.g., 90 days
        uint256 term;
        // the repayment interval - e.g., 30 days
        uint256 epoch;
        // number of instalments, term / epoch
        uint8 nper;
        // the amount to be repaid per instalment (principal + interest)
        // fv (0) + pv (principal) *(1+rate)**nper + pmt*(1 + rate*when)/rate*((1 + rate)**nper – 1)
        uint256 pmt;
        // the borrow rate of this loan
        uint256 vaultBorrowRate;
        // the adjusted borrow rate
        // adjustedBorrowRate always > vaultBorrowRate
        uint256 adjustedBorrowRate;
        // uint40 timestamp;
        // uint256 borrowRate;
        Repayment repayment;
        // about to drop
        uint40 timestamp;
        uint256 tenure;
        uint256 borrowRate;
    }

    struct DebtDetail {
        uint256 amount;
        uint256 tenure;
        uint40 timestamp;
        uint256 borrowRate;
    }

    struct Repayment {
        uint256 totalPaid;
        uint256 principalPaid;
        uint256 interestPaid;
        uint256 numPayments;
        // tenure => amount
        // todo wrapper this in the future
        mapping(uint256 => uint256) payments;
    }

    struct RepaymentDetail {
        uint256 totalPaid;
        uint256 numPayments;
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
        uint256 utilizationRate;
        uint256 trancheRatio;
        uint256 decimals;
        string symbol;
        bool isActive;
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
        uint256 decimals;
    }
}

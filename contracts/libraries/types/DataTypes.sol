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
        uint256 currentBorrowRate;
        // Expressed in ray
        uint256 securityRequirement;
        //the decimals of the reserve asset
        uint256 decimals;
        address interestRateStrategyAddress;
        address healthStrategyAddress;
        address loanStrategyAddress;
        address juniorDepositTokenAddress;
        address seniorDepositTokenAddress;
        uint40 juniorLastUpdateTimestamp;
        uint40 seniorLastUpdateTimestamp;
        uint256 optimalTrancheRatio;
        uint256 currentIncomeRatio;
        uint256 optimalIncomeRatio;
        address nftAddress;
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

    struct BorrowData {
        uint256 paidDrawDownNumber;
        // next draw down number
        uint256 nextDrawDownNumber;
        uint256 totalPrincipal;
        uint256 totalInterest;
        uint256 mapSize;
        mapping(uint256 => DrawDown) drawDowns;
    }

    struct BorrowStat {
        uint256 totalDebt;
        uint256 totalInterest;
        uint256 avgBorrowRate;
    }

    struct PMT {
        uint256 principal;
        uint256 interest;
        uint256 pmt;
    }

    struct DrawDown {
        uint256 principal;
        // the total intended length of the loan in seconds - e.g., 90 days
        uint256 term;
        // the repayment interval - e.g., 30 days
        uint256 epoch;
        // number of instalments, term / epoch
        uint256 nper;
        // the amount to be repaid per instalment (principal + interest)
        PMT pmt;
        // the borrow rate of this loan
        uint256 apr;
        uint256 borrowAt;
        // next due data
        uint256 nextPaymentDue;
        // principal paid
        uint256 totalPrincipalPaid;
        // interest paid
        uint256 totalInterestPaid;
        RepaymentData[] repayments;
        // size pf repayments
        uint256 paidTimes;
    }

    struct DebtDetail {
        uint256 principal;
        uint256 term;
        uint256 epoch;
        uint256 nper;
        PMT pmt;
        uint256 apr;
        uint256 borrowAt;
        uint256 nextPaymentDue;
        uint256 totalPrincipalPaid;
        uint256 totalInterestPaid;
        uint256 paidTimes;
    }

    struct RepaymentData {
        uint256 principal;
        uint256 interest;
        // principal + interest
        uint256 total;
        uint40 paidAt;
        bool isLiquidated;
    }

    struct Repayment {
        uint256 principal;
        uint256 interest;
        // principal + interest
        uint256 total;
        uint40 paidAt;
        // about to drop
        uint256 totalPaid;
        uint256 principalPaid;
        uint256 interestPaid;
        uint256 numPayments;
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
        uint256 totalInterest;
        uint256 avgBorrowRate;
    }

    struct HealthRiskParameter {
        uint256 securityDeposit;
        uint256 currentBorrowRate;
        uint256 compoundedDebt;
        uint256 grossAssetValue;
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
        uint256 utilizationRate;
        uint256 trancheRatio;
        uint256 decimals;
        string symbol;
        bool isActive;
    }

    struct DrawDownList {
        uint256 head;
        uint256 tail;
    }

    struct VaultData {
        uint256 borrowRate;
        uint256 totalDebt;
        DrawDownList drawDownList;
        uint256 totalSecurityDeposit;
        uint256 withdrawableSecurityDeposit;
        uint256 creditLimit;
        uint256 spendableBalance;
        uint256 gav;
        uint256 ltv;
        uint256 healthFactor;
    }

    struct UserPoolData {
        uint256 juniorTrancheBalance;
        uint256 withdrawableJuniorTrancheBalance;
        uint256 seniorTrancheBalance;
        uint256 withdrawableSeniorTrancheBalance;
        uint256 decimals;
    }

    struct Heap {
        uint256[] heapList;
        uint256 currentSize;
    }
}

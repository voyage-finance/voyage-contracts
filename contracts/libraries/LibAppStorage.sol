// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

bytes32 constant ADDRESS_RESOLVER = "address_resolver";

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

struct PMT {
    uint256 principal;
    uint256 interest;
    uint256 pmt;
}

struct RepaymentData {
    uint256 principal;
    uint256 interest;
    // principal + interest
    uint256 total;
    uint40 paidAt;
    bool isLiquidated;
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

struct BorrowData {
    uint256 paidDrawDownNumber;
    // next draw down number
    uint256 nextDrawDownNumber;
    uint256 totalPrincipal;
    uint256 totalInterest;
    uint256 mapSize;
    mapping(uint256 => DrawDown) drawDowns;
}

struct BorrowState {
    uint256 totalDebt;
    uint256 totalInterest;
    uint256 avgBorrowRate;
}

struct AppStorage {
    /* -------------------------------- plumbing -------------------------------- */
    mapping(bytes32 => address) _addresses;
    /* -------------------------------- liquidity ------------------------------- */
    mapping(address => ReserveData) _reserves;
    // List of reserves as a map (reserveId => reserve)
    mapping(uint256 => address) _reserveList;
    uint16 _reservesCount;
    /* ---------------------------------- debt ---------------------------------- */
    mapping(address => mapping(address => BorrowData)) _borrowData;
    mapping(address => BorrowState) _borrowState;
    bool _paused;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

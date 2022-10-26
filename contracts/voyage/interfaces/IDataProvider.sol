// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LoanList, RepaymentData} from "../libraries/LibAppStorage.sol";
import {LibLoan} from "../libraries/LibLoan.sol";

struct CreditLineData {
    uint256 totalDebt;
    LoanList loanList;
    uint256 gav;
    uint256 ltv;
    uint256 healthFactor;
}

struct PoolData {
    address currency;
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

struct UserPoolData {
    uint256 juniorTrancheBalance;
    uint256 seniorTrancheBalance;
    uint256 withdrawableSeniorTrancheBalance;
    uint256 decimals;
}

struct PoolConfiguration {
    uint256 liquidationBonus;
    uint256 loanInterval;
    uint256 loanTenure;
    uint256 incomeRatio;
    bool isInitialized;
    bool isActive;
}

interface IDataProvider {
    function getPoolConfiguration(address _collection)
        external
        view
        returns (PoolConfiguration memory);

    function getPoolData(address _collection)
        external
        view
        returns (PoolData memory);

    function getDepositTokens(address _collection)
        external
        view
        returns (address senior, address junior);

    function getVault(address _user) external view returns (address);

    function getCollections() external view returns (address[] memory);

    function getUserPoolData(address _collection, address _user)
        external
        view
        returns (UserPoolData memory);

    function getCreditLineData(address _vault, address _collection)
        external
        view
        returns (CreditLineData memory);

    function getLoanDetail(
        address _vault,
        address _collection,
        uint256 _loanId
    ) external view returns (LibLoan.LoanDetail memory);

    function getRepayment(
        address _valut,
        address _collection,
        uint256 _loanId
    ) external view returns (RepaymentData[] memory);

    function pendingSeniorWithdrawals(address _user, address _collection)
        external
        view
        returns (uint256);

    function getProtocolFeeParam() external view returns (address, uint256);
}

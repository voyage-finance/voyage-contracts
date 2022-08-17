// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**
@title IReserveInterestRateStrategyInterface interface
@notice Interface for the calculation of the interest rates.
*/

interface IReserveInterestRateStrategy {
    function calculateBorrowRate(
        address reserve,
        address seniorDepositTokenAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt
    ) external view returns (uint256);
}

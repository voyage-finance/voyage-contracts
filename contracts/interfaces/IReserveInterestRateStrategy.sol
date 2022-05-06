// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**
@title IReserveInterestRateStrategyInterface interface
@notice Interface for the calculation of the interest rates.
*/

interface IReserveInterestRateStrategy {
    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 averageBorrowRate
    ) external view returns (uint256, uint256);

    function calculateInterestRates(
        address reserve,
        address seniorDepositToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt,
        uint256 averageBorrowRate
    ) external view returns (uint256, uint256);
}

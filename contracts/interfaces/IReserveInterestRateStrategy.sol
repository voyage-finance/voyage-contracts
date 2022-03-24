pragma solidity ^0.8.9;

/**
@title IReserveInterestRateStrategyInterface interface
@notice Interface for the calculation of the interest rates.
*/

interface IReserveInterestRateStrategy {
    /**
     * @dev returns the base borrow rate, in rays
     */

    function getBaseBorrowRate() external view returns (uint256);

    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalStableDebt
    ) external view returns (uint256, uint256);

    function calculateInterestRates(
        address reserve,
        address juniorDepositToken,
        address seniorDepositToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt
    ) external view returns (uint256, uint256);
}

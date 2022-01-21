pragma solidity  ^0.8.9;

/**
@title IReserveInterestRateStrategyInterface interface
@notice Interface for the calculation of the interest rates.
*/

interface IReserveInterestRateStrategy {

    /**
    * @dev returns the base variable borrow rate, in rays
    */

    function getBaseVariableBorrowRate() external view returns (uint256);

    /**
    * @dev calculates the liquidity, rates depending on the current utilization rate
    *      and the base parameters
    *
    */
    function calculateInterestRates(
        address _reserve,
        uint256 _utilizationRate,
        uint256 _totalBorrows
    ) external view returns (uint256);
}

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
}

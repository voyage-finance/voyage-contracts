// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IStableDebtToken {
    /**
     * @dev Returns the average rate of all the stable rate loans.
     * @return The average stable rate
     **/
    function getAverageStableRate() external view returns (uint256);

    /**
     * @dev Returns the total supply and the average stable rate
     **/
    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256);
}

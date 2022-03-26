// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IStableDebtToken {
    function getAverageStableRate() external view returns (uint256);

    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../libraries/types/DataTypes.sol";

interface IHealthStrategy {
    function getPremiumFactor() external view returns (uint256);

    function getLoanTenure() external view returns (uint256);

    function getWeightedLTV() external view returns (uint256);

    function getWeightedRepaymentRatio() external view returns (uint256);

    function calculateHealthRisk(DataTypes.HealthRiskParameter memory)
        external
        view
        returns (uint256);
}

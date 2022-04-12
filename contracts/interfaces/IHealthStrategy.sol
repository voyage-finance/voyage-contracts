// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';

interface IHealthStrategy {
    function calculateHealthRisk(DataTypes.HealthRiskParameter memory)
        external
        view
        returns (uint256);
}

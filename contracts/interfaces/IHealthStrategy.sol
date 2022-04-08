// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../libraries/types/DataTypes.sol";

interface IHealthStrategy {
    function getPrincipalDebt(DataTypes.DrawDown memory _drawDown)
    external
    view
    returns (uint256);

    function calculateHealthRisk(
        uint256 _securityDeposit,
        DataTypes.DrawDown memory _drawDown
    ) external view returns (uint256);
}

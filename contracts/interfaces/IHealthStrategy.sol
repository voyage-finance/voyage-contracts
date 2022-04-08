// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';

interface IHealthStrategy {
    function calculateHealthRisk(
        uint256 _securityDeposit,
        uint256 _currentBorrowRate,
        uint40 _lastTimestamp,
        DataTypes.DrawDown memory _drawDown,
        uint256 _grossAssetValue
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IHealthStrategy {
    function calculateHealthRisk(
        uint256 _securityDeposit,
        uint256 _currentBorrowRate,
        uint40 _lastTimestamp,
        uint256 _amount,
        uint256 _grossAssetValue,
        uint256 _aggregateOptimalRepaymentRate,
        uint256 _aggregateActualRepaymentRate
    ) external view returns (uint256);
}

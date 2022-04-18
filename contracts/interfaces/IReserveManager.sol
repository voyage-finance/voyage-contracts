// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/logic/ReserveLogic.sol';

interface IReserveManager {
    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress
    ) external;

    function activeReserve(address _asset) external;

    function getReserveData(address _asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getReserveList() external view returns (address[] memory);

    function getConfiguration(address _asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    function getFlags(address _asset)
        external
        view
        returns (
            bool,
            bool,
            bool
        );

    function getLiquidityRate(address _reserve, ReserveLogic.Tranche _tranche)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/logic/ReserveLogic.sol';

interface ILiquidityManagerProxy {
    function getLiquidityRate(address _reserve, ReserveLogic.Tranche _tranche)
        external
        view
        returns (uint256);

    function getReserveData(address _reserve)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getConfiguration(address _reserve)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);
}

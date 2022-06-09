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

    function getLiquidityAndDebt(address _reserve)
        external
        view
        returns (DataTypes.DepositAndDebt memory);

    function getFlags(address _asset)
        external
        view
        returns (
            bool,
            bool,
            bool
        );

    function getConfiguration(address _reserve)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    function balance(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);

    function utilizationRate(address _reserve) external view returns (uint256);
}

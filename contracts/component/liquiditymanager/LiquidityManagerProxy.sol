// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../../interfaces/ILiquidityManagerProxy.sol';

contract LiquidityManagerProxy is Proxy {
    function getLiquidityRate(address _reserve, ReserveLogic.Tranche _tranche)
        external
        view
        returns (uint256)
    {
        return
            ILiquidityManager(address(target)).getLiquidityRate(
                _reserve,
                _tranche
            );
    }

    function getReserveData(address _reserve)
        external
        view
        returns (DataTypes.ReserveData memory)
    {
        return ILiquidityManager(address(target)).getReserveData(_reserve);
    }

    function getConfiguration(address _reserve)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return ILiquidityManager(address(target)).getConfiguration(_reserve);
    }

    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        return
            ILiquidityManager(address(target)).getReserveNormalizedIncome(
                _asset,
                _tranche
            );
    }
}

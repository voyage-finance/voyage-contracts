// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../libraries/logic/ReserveLogic.sol';

contract LiquidityManagerProxy is Proxy {
    function getLiquidityRate(address _reserve, ReserveLogic.Tranche _tranche)
        external
        view
        returns (uint256)
    {
        return
            IReserveManager(address(target)).getLiquidityRate(
                _reserve,
                _tranche
            );
    }

    function getReserveData(address _reserve)
        external
        view
        returns (DataTypes.ReserveData memory)
    {
        return IReserveManager(address(target)).getReserveData(_reserve);
    }

    function getReserveList()
        external
        view
        returns (address[] memory)
    {
        return IReserveManager(address(target)).getReserveList();
    }

    function getConfiguration(address _reserve)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return IReserveManager(address(target)).getConfiguration(_reserve);
    }

    function getFlags(address _asset)
        external
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return IReserveManager(address(target)).getFlags(_asset);
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

    function getEscrowAddress() external view returns (address) {
        return ILiquidityManager(address(target)).getEscrowAddress();
    }
}

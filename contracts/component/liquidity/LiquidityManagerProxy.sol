// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Proxy} from "../../libraries/proxy/Proxy.sol";
import {IReserveManager} from "../../interfaces/IReserveManager.sol";
import {ILiquidityManager} from "../../interfaces/ILiquidityManager.sol";
import {ILiquidityManagerProxy} from "../../interfaces/ILiquidityManagerProxy.sol";
import {IVoyagerComponent} from "../../interfaces/IVoyagerComponent.sol";
import {ReserveLogic} from "../../libraries/logic/ReserveLogic.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";

contract LiquidityManagerProxy is Proxy, ILiquidityManagerProxy {
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

    function getLiquidityAndDebt(address _reserve)
        external
        view
        returns (DataTypes.DepositAndDebt memory)
    {
        return IVoyagerComponent(address(target)).getDepositAndDebt(_reserve);
    }

    function getReserveList() external view returns (address[] memory) {
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

    function balance(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        return
            ILiquidityManager(address(target)).balance(
                _reserve,
                _user,
                _tranche
            );
    }

    function utilizationRate(address _reserve) external view returns (uint256) {
        return ILiquidityManager(address(target)).utilizationRate(_reserve);
    }
}

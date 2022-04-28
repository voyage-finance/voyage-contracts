// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/IReserveManager.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../interfaces/ILiquidityManagerProxy.sol';
import '../../interfaces/IVoyagerComponent.sol';
import '../../libraries/logic/ReserveLogic.sol';
import 'hardhat/console.sol';

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
        console.log('in getLiquidityAndDebt');
        return IVoyagerComponent(address(target)).getDepositAndDebt();
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

    function withdrawAbleAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256) {
        return
            ILiquidityManager(address(target)).withdrawAbleAmount(
                _reserve,
                _user,
                _tranche
            );
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

    function getEscrowAddress() external view returns (address) {
        return ILiquidityManager(address(target)).getEscrowAddress();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/state/State.sol';
import '../../libraries/types/DataTypes.sol';
import '../../libraries/logic/ReserveLogic.sol';

contract LiquidityManagerStorage is State {
    using ReserveLogic for DataTypes.ReserveData;

    mapping(address => DataTypes.ReserveData) internal _reserves;

    constructor(address _liquidityManager) State(_liquidityManager) {}

    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress
    ) external onlyAssociatedContract {
        _reserves[_asset].init(
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _juniorIncomeAllocation,
            _seniorIncomeAllocation,
            _stableDebtAddress,
            _interestRateStrategyAddress
        );
    }

    function getReserveData(address _asset)
        public
        view
        returns (DataTypes.ReserveData memory)
    {
        return _reserves[_asset];
    }

    function getConfiguration(address _asset)
        public
        view
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return _reserves[_asset].configuration;
    }

    function getLiquidityRate(address _asset, ReserveLogic.Tranche _tranche)
        public
        view
        returns (uint256)
    {
        return _reserves[_asset].getLiquidityRate(_tranche);
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/state/State.sol';
import '../../libraries/types/DataTypes.sol';
import '../../libraries/logic/ReserveLogic.sol';

contract LiquidityStorage is State {
    using ReserveLogic for DataTypes.ReserveData;

    mapping(address => DataTypes.ReserveData) internal _reserves;

    constructor(address _liquidityManager) State(_liquidityManager) {}

    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _stableDebtAddress,
        address _interestRateStrategyAddress
    ) external onlyAssociatedContract {
        _reserves[_asset].init(
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _stableDebtAddress,
            _interestRateStrategyAddress
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../math/WadRayMath.sol';
import '../types/DataTypes.sol';

/**
 * @title ReserveLogic library
 * @author Voyager
 * @notice Implements the logic to update the reserves state
 **/
library ReserveLogic {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    using ReserveLogic for DataTypes.ReserveData;

    function init(
        DataTypes.ReserveData storage reserve,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _stableDebtAddress,
        address _interestRateStrategyAddress
    ) external {
        reserve.currentJuniorLiquidityIndex = WadRayMath.ray();
        reserve.currentSeniorLiquidityIndex = WadRayMath.ray();
        reserve.juniorDepositTokenAddress = _juniorDepositTokenAddress;
        reserve.seniorDepositTokenAddress = _seniorDepositTokenAddress;
        reserve.stableDebtAddress = _stableDebtAddress;
        reserve.interestRateStrategyAddress = _interestRateStrategyAddress;
    }
}

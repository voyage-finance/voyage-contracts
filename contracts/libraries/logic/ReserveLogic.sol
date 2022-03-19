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

    enum Tranche {
        JUNIOR,
        SENIOR
    }

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

    function updateState(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) internal {}

    function _getLiquidityRate(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) internal returns (uint256) {
        uint256 totalAllocationInRay = reserve
            .currentJuniorIncomeAllocation
            .add(reserve.currentSeniorIncomeAllocation);
        if (_tranche == Tranche.JUNIOR) {
            return
                reserve.currentOverallLiquidityRate.rayMul(
                    reserve.currentJuniorIncomeAllocation.rayDiv(
                        totalAllocationInRay
                    )
                );
        } else {
            return
                reserve.currentOverallLiquidityRate.rayMul(
                    reserve.currentSeniorIncomeAllocation.rayDiv(
                        totalAllocationInRay
                    )
                );
        }
    }

    function _updateIndexes(
        DataTypes.ReserveData storage reserve,
        uint256 _juniorLiquidityIndex,
        uint256 _seniorLiquidityIndex
    ) internal {}
}

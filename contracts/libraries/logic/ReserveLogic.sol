// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../math/WadRayMath.sol';
import '../math/MathUtils.sol';
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
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress
    ) external {
        reserve.juniorLiquidityIndex = WadRayMath.ray();
        reserve.seniorLiquidityIndex = WadRayMath.ray();
        reserve.juniorDepositTokenAddress = _juniorDepositTokenAddress;
        reserve.seniorDepositTokenAddress = _seniorDepositTokenAddress;
        reserve.currentJuniorIncomeAllocation = _juniorIncomeAllocation;
        reserve.currentSeniorIncomeAllocation = _seniorIncomeAllocation;
        reserve.stableDebtAddress = _stableDebtAddress;
        reserve.interestRateStrategyAddress = _interestRateStrategyAddress;
    }

    function updateState(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) internal {}

    function getLiquidityRate(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) public view returns (uint256) {
        return reserve._getLiquidityRate(_tranche);
    }

    function _getLiquidityRate(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) internal view returns (uint256) {
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
        Tranche _tranche
    ) internal {
        if (_tranche == Tranche.JUNIOR) {
            uint256 previousJuniorLiquidityIndex = reserve.juniorLiquidityIndex;
            uint256 lastJuniorUpdatedTimestamp = reserve
                .juniorLastUpdateTimestamp;
            reserve._updateJuniorLiquidityIndex(
                previousJuniorLiquidityIndex,
                uint40(lastJuniorUpdatedTimestamp)
            );
        } else {
            uint256 previousSeniorLiquidityIndex = reserve.seniorLiquidityIndex;
            uint256 lastSeniorUpdatedTimestamp = reserve
                .seniorLastUpdateTimestamp;
            reserve._updateSeniorLiquidityIndex(
                previousSeniorLiquidityIndex,
                uint40(lastSeniorUpdatedTimestamp)
            );
        }
    }

    function _updateJuniorLiquidityIndex(
        DataTypes.ReserveData storage reserve,
        uint256 juniorLiquidityIndex,
        uint40 timestamp
    ) internal returns (uint256) {
        uint256 juniorLiquidityRate = reserve._getLiquidityRate(Tranche.JUNIOR);
        uint256 newJuniorLiquidityIndex = juniorLiquidityIndex;

        // only cumulating if there is any income being produced
        if (juniorLiquidityRate > 0) {
            uint256 cumulatedLiquidityInterest = MathUtils
                .calculateLinearInterest(juniorLiquidityRate, timestamp);
            newJuniorLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                juniorLiquidityIndex
            );
            reserve.juniorLiquidityIndex = newJuniorLiquidityIndex;
        }

        reserve.juniorLastUpdateTimestamp = uint40(block.timestamp);
        return newJuniorLiquidityIndex;
    }

    function _updateSeniorLiquidityIndex(
        DataTypes.ReserveData storage reserve,
        uint256 seniorLiquidityIndex,
        uint40 timestamp
    ) internal returns (uint256) {
        uint256 seniorLiquidityRate = reserve._getLiquidityRate(Tranche.SENIOR);
        uint256 newSeniorLiquidityIndex = seniorLiquidityIndex;

        if (seniorLiquidityRate > 0) {
            uint256 cumulatedLiquidityInterest = MathUtils
                .calculateLinearInterest(seniorLiquidityRate, timestamp);
            newSeniorLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                seniorLiquidityIndex
            );
            reserve.seniorLiquidityIndex = newSeniorLiquidityIndex;
        }
        reserve.seniorLastUpdateTimestamp = uint40(block.timestamp);
        return newSeniorLiquidityIndex;
    }
}

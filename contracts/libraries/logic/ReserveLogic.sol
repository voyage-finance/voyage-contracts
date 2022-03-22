// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import '../math/WadRayMath.sol';
import '../math/MathUtils.sol';
import '../types/DataTypes.sol';
import '../../component/liquiditymanager/DefaultReserveInterestRateStrategy.sol';

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

    struct UpdateInterestRatesLocalVars {
        address stableDebtTokenAddress;
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 newLiquidityRate;
        uint256 newStableRate;
    }

    function updateInterestRates(
        DataTypes.ReserveData storage _reserve,
        address _reserveAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) internal {
        UpdateInterestRatesLocalVars memory vars;

        vars.stableDebtTokenAddress = _reserve.stableDebtAddress;

        // todo debt token

        //        IReserveInterestRateStrategy(_reserve.interestRateStrategyAddress).calculateInterestRates(_reserveAddress, )
    }

    function getNormalizedIncome(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) internal view returns (uint256) {
        uint40 timestamp;
        uint256 liquidityIndex;
        if (_tranche == Tranche.JUNIOR) {
            timestamp = reserve.juniorLastUpdateTimestamp;
            liquidityIndex = reserve.juniorLiquidityIndex;
        } else {
            timestamp = reserve.seniorLastUpdateTimestamp;
            liquidityIndex = reserve.seniorLiquidityIndex;
        }

        //solium-disable-next-line
        if (timestamp == uint40(block.timestamp)) {
            return liquidityIndex;
        }

        uint256 cumulated = MathUtils
            .calculateLinearInterest(
                reserve._getLiquidityRate(_tranche),
                timestamp
            )
            .rayMul(liquidityIndex);
        return cumulated;
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

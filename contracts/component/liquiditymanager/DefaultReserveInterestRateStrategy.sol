// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/math/WadRayMath.sol';
import '../../interfaces/IReserveInterestRateStrategy.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

contract DefaultReserveInterestRateStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;
    /**
     * this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates
     * Expressed in RAY
     **/
    uint256 public immutable OPTIMAL_UTILIZATION_RATE;

    // Base interest rate set by governance. Expressed in ray
    uint256 internal immutable baseBorrowRate;

    // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable stableRateSlope1;

    // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable stableRateSlope2;

    constructor(
        uint256 _optimalUtilizationRate,
        uint256 _baseBorrowRate,
        uint256 _stableRateSlope1,
        uint256 _stableRateSlope2
    ) public {
        OPTIMAL_UTILIZATION_RATE = _optimalUtilizationRate;
        baseBorrowRate = _baseBorrowRate;
        stableRateSlope1 = _stableRateSlope1;
        stableRateSlope2 = _stableRateSlope2;
    }

    struct CalcInterestRatesLocalVars {
        uint256 totalDebt;
        uint256 currentStableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configuration
     * @param reserve The address of the reserve
     * @param depositToken Either junior deposit token or senior deposit token
     * @param liquidityAdded The liquidity added during the operation
     * @param liquidityTaken The liquidity taken during the operation
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     **/
    function calculateInterestRates(
        address reserve,
        address depositToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt
    ) external view returns (uint256, uint256) {
        uint256 availableLiquidity = IERC20(reserve).balanceOf(depositToken);
        availableLiquidity = availableLiquidity.add(liquidityAdded).sub(
            liquidityTaken
        );
        return
            calculateInterestRates(
                reserve,
                availableLiquidity,
                totalStableDebt
            );
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * @param reserve The address of the reserve
     * @param availableLiquidity The liquidity available in the corresponding aToken
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @return The liquidity rate, the stable borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalStableDebt
    ) public view returns (uint256, uint256) {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = totalStableDebt;
        vars.currentStableBorrowRate = baseBorrowRate;
        vars.currentLiquidityRate = 0;

        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity.add(vars.totalDebt));

        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            vars.currentStableBorrowRate = vars
                .currentStableBorrowRate
                .add(stableRateSlope1)
                .add(
                    stableRateSlope2
                        .rayMul(
                            vars.utilizationRate.sub(OPTIMAL_UTILIZATION_RATE)
                        )
                        .rayDiv(WadRayMath.Ray().sub(OPTIMAL_UTILIZATION_RATE))
                );
        } else {
            vars.currentStableBorrowRate = vars.currentStableBorrowRate.add(
                stableRateSlope1.rayMul(vars.utilizationRate).rayDiv(
                    OPTIMAL_UTILIZATION_RATE
                )
            );
        }

        vars.currentLiquidityRate = vars.currentStableBorrowRate.rayMul(
            vars.utilizationRate
        );
        return (vars.currentLiquidityRate, vars.currentStableBorrowRate);
    }
}

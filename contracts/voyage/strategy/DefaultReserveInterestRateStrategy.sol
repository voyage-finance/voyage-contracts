// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";

contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
    using WadRayMath for uint256;
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
        uint256 _stableRateSlope1,
        uint256 _stableRateSlope2,
        uint256 _baseBorrowRate
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
     * @param seniorDepositTokenAddress The address of senior deposit token
     * @param liquidityAdded The liquidity added during the operation
     * @param liquidityTaken The liquidity taken during the operation
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param averageBorrowRate The current average borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        address seniorDepositTokenAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt,
        uint256 averageBorrowRate
    ) external view returns (uint256, uint256) {
        uint256 totalPendingWithdrawal = IVToken(seniorDepositTokenAddress)
            .totalUnbonding();

        uint256 availableLiquidity = IERC20(reserve).balanceOf(
            seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        availableLiquidity =
            availableLiquidity +
            liquidityAdded -
            liquidityTaken;
        return
            calculateInterestRates(
                reserve,
                availableLiquidity,
                totalStableDebt,
                averageBorrowRate
            );
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * @param reserve The address of the reserve
     * @param availableLiquidity The liquidity available in the corresponding aToken
     * @param totalStableDebt The total borrowed from the reserve a stable rate
     * @param averageBorrowRate The current average borrow rate
     * @return The liquidity rate, the stable borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 averageBorrowRate
    ) public view returns (uint256, uint256) {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = totalStableDebt;
        vars.currentStableBorrowRate = baseBorrowRate;
        vars.currentLiquidityRate = 0;

        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity + vars.totalDebt);

        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            vars.currentStableBorrowRate =
                vars.currentStableBorrowRate +
                stableRateSlope1 +
                (
                    stableRateSlope2
                        .rayMul(vars.utilizationRate - OPTIMAL_UTILIZATION_RATE)
                        .rayDiv(WadRayMath.Ray() - OPTIMAL_UTILIZATION_RATE)
                );
        } else {
            vars.currentStableBorrowRate =
                vars.currentStableBorrowRate +
                (
                    stableRateSlope1.rayMul(vars.utilizationRate).rayDiv(
                        OPTIMAL_UTILIZATION_RATE
                    )
                );
        }

        vars.currentLiquidityRate = averageBorrowRate.rayMul(
            vars.utilizationRate
        );
        return (vars.currentLiquidityRate, vars.currentStableBorrowRate);
    }
}

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

    // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable stableRateSlope;

    constructor(
        uint256 _optimalUtilizationRate,
        uint256 _stableRateSlope,
        uint256 _baseBorrowRate
    ) {
        OPTIMAL_UTILIZATION_RATE = _optimalUtilizationRate;
        baseBorrowRate = _baseBorrowRate;
        stableRateSlope = _stableRateSlope;
    }

    struct CalcInterestRatesLocalVars {
        uint256 totalDebt;
        uint256 currentStableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    function calculateBorrowRate(
        address reserve,
        address seniorDepositTokenAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalStableDebt
    ) external view returns (uint256) {
        CalcInterestRatesLocalVars memory vars;
        vars.totalDebt = totalStableDebt;
        vars.currentStableBorrowRate = baseBorrowRate;

        uint256 totalPendingWithdrawal = IVToken(seniorDepositTokenAddress)
            .totalUnbonding();

        uint256 availableLiquidity = IERC20(reserve).balanceOf(
            seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        availableLiquidity =
            availableLiquidity +
            liquidityAdded -
            liquidityTaken;

        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity + vars.totalDebt);
        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            vars.currentStableBorrowRate =
                vars.currentStableBorrowRate +
                (
                    stableRateSlope
                        .rayMul(vars.utilizationRate - OPTIMAL_UTILIZATION_RATE)
                        .rayDiv(WadRayMath.Ray() - OPTIMAL_UTILIZATION_RATE)
                );
        }
        return vars.currentStableBorrowRate;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/math/WadRayMath.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../shared/escrow/LiquidityDepositEscrow.sol';
import '../../interfaces/IReserveInterestRateStrategy.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import 'hardhat/console.sol';

contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
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
        uint256 currentBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configuration
     * @param reserve The address of the reserve undelrying asset
     * @param liquidityEscrow The address of junior deposit token
     * @param liquidityAdded The liquidity added during the operation
     * @param liquidityTaken The liquidity taken during the operation
     * @param totalDebt The total borrowed from the reserve a stable rate
     * @param averageBorrowRate The current average borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        address liquidityEscrow,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalDebt,
        uint256 averageBorrowRate
    ) external view returns (uint256, uint256) {
        uint256 availableLiquidity = LiquidityDepositEscrow(liquidityEscrow)
            .balanceOfTranche(ReserveLogic.Tranche.SENIOR);
        availableLiquidity = availableLiquidity.add(liquidityAdded).sub(
            liquidityTaken
        );
        return
            calculateInterestRates(
                reserve,
                availableLiquidity,
                totalDebt,
                averageBorrowRate
            );
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * @param reserve The address of the reserve
     * @param availableLiquidity The liquidity available in the corresponding tranche liquidity token
     * @param totalDebt total debt that has accumulated
     * @return The liquidity rate, the stable borrow rate
     * @param averageBorrowRate The current average borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        uint256 availableLiquidity,
        uint256 totalDebt,
        uint256 averageBorrowRate
    ) public view returns (uint256, uint256) {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = totalDebt;
        vars.currentBorrowRate = baseBorrowRate;
        vars.currentLiquidityRate = 0;

        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity.add(vars.totalDebt));

        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            vars.currentBorrowRate = vars
                .currentBorrowRate
                .add(stableRateSlope1)
                .add(
                    stableRateSlope2
                        .rayMul(
                            vars.utilizationRate.sub(OPTIMAL_UTILIZATION_RATE)
                        )
                        .rayDiv(WadRayMath.Ray().sub(OPTIMAL_UTILIZATION_RATE))
                );
        } else {
            vars.currentBorrowRate = vars.currentBorrowRate.add(
                stableRateSlope1.rayMul(vars.utilizationRate).rayDiv(
                    OPTIMAL_UTILIZATION_RATE
                )
            );
        }

        vars.currentLiquidityRate = averageBorrowRate.rayMul(
            vars.utilizationRate
        );
        return (vars.currentLiquidityRate, vars.currentBorrowRate);
    }
}

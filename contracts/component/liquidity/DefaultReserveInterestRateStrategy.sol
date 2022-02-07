// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../interfaces/IReserveInterestRateStrategy.sol';
import '../../libraries/math/WadRayMath.sol';
import './LiquidityManager.sol';
import '../../interfaces/ILendingRateOracle.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';

/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice implements the calculation of the interest rates depending on the reserve parameters.
 * @dev if there is need to update the calculation of the interest rates for a specific reserve,
 * a new version of this contract will be deployed.
 * @author Aave
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    /**
     * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates
     * expressed in ray
     **/
    uint256 public constant OPTIMAL_UTILIZATION_RATE = 0.8 * 1e27;

    /**
     * @dev this constant represents the excess utilization rate above the optimal. It's always equal to
     * 1-optimal utilization rate. Added as a constant here for gas optimizations
     * expressed in ray
     **/

    uint256 public constant EXCESS_UTILIZATION_RATE = 0.2 * 1e27;

    //base variable borrow rate when Utilization rate = 0. Expressed in ray
    uint256 public baseVariableBorrowRate;

    //slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public variableRateSlope1;

    //slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public variableRateSlope2;

    //slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public stableRateSlope1;

    //slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 public stableRateSlope2;
    address public reserve;

    constructor(
        address _reserve,
        uint256 _baseVariableBorrowRate,
        uint256 _variableRateSlope1,
        uint256 _variableRateSlope2,
        uint256 _stableRateSlope1,
        uint256 _stableRateSlope2
    ) public {
        baseVariableBorrowRate = _baseVariableBorrowRate;
        variableRateSlope1 = _variableRateSlope1;
        variableRateSlope2 = _variableRateSlope2;
        stableRateSlope1 = _stableRateSlope1;
        stableRateSlope2 = _stableRateSlope2;
        reserve = _reserve;
    }

    /**
    @dev accessors
     */

    function getBaseVariableBorrowRate() external view returns (uint256) {
        return baseVariableBorrowRate;
    }

    function getVariableRateSlope1() external view returns (uint256) {
        return variableRateSlope1;
    }

    function getVariableRateSlope2() external view returns (uint256) {
        return variableRateSlope2;
    }

    function getStableRateSlope1() external view returns (uint256) {
        return stableRateSlope1;
    }

    function getStableRateSlope2() external view returns (uint256) {
        return stableRateSlope2;
    }

    /**
     * @dev calculates the overall borrow rate as the weighted average between the total variable borrows and total stable borrows.
     * @param _totalBorrowsStable the total borrowed from the reserve a stable rate
     * @param _totalBorrowsVariable the total borrowed from the reserve at a variable rate
     * @param _currentVariableBorrowRate the current variable borrow rate
     * @param _currentAverageStableBorrowRate the weighted average of all the stable rate borrows
     * @return the weighted averaged borrow rate
     **/
    function getOverallBorrowRateInternal(
        uint256 _totalBorrowsStable,
        uint256 _totalBorrowsVariable,
        uint256 _currentVariableBorrowRate,
        uint256 _currentAverageStableBorrowRate
    ) internal pure returns (uint256) {
        uint256 totalBorrows = _totalBorrowsStable.add(_totalBorrowsVariable);

        if (totalBorrows == 0) return 0;

        uint256 weightedVariableRate = _totalBorrowsVariable.wadToRay().rayMul(
            _currentVariableBorrowRate
        );

        uint256 weightedStableRate = _totalBorrowsStable.wadToRay().rayMul(
            _currentAverageStableBorrowRate
        );

        uint256 overallBorrowRate = weightedVariableRate
            .add(weightedStableRate)
            .rayDiv(totalBorrows.wadToRay());

        return overallBorrowRate;
    }

    /**
     * @dev calculates the liquidity, rates depending on the current utilization rate
     *      and the base parameters
     *
     */
    function calculateInterestRates(
        address _reserve,
        uint256 _utilizationRate,
        uint256 _totalBorrows
    ) external view returns (uint256 liquidityRate) {
        //todo
        return 0;
    }
}

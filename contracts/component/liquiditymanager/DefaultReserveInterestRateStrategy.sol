// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract DefaultReserveInterestRateStrategy {
    /**
     * this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates
     * Expressed in RAY
     **/
    uint256 public immutable OPTIMAL_UTILIZATION_RATE;

    // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable stableRateSlope1;

    // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable stableRateSlope2;

    constructor(
        uint256 optimalUtilizationRate,
        uint256 _stableRateSlope1,
        uint256 _stableRateSlope2
    ) public {
        OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
        stableRateSlope1 = _stableRateSlope1;
        stableRateSlope2 = _stableRateSlope2;
    }
}

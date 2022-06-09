// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "../math/WadRayMath.sol";
import "../math/MathUtils.sol";
import "../types/DataTypes.sol";
import "../helpers/Errors.sol";
import "../../component/liquidity/DefaultReserveInterestRateStrategy.sol";
import "hardhat/console.sol";

/**
 * @title ReserveLogic library
 * @author Voyage
 * @notice Implements the logic to update the reserves state
 **/
library ReserveLogic {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant RAY = 1e27;

    using ReserveLogic for DataTypes.ReserveData;

    enum Tranche {
        JUNIOR,
        SENIOR
    }

    /**
     * @dev Emitted when the state of a reserve is updated
     * @param asset The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     **/
    event ReserveDataUpdated(
        address indexed asset,
        uint256 liquidityRate,
        uint256 stableBorrowRate
    );

    function init(
        DataTypes.ReserveData storage reserve,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress,
        address _loanStrategyAddress,
        uint256 _optimalIncomeRatio
    ) external {
        reserve.juniorDepositTokenAddress = _juniorDepositTokenAddress;
        reserve.seniorDepositTokenAddress = _seniorDepositTokenAddress;
        reserve.interestRateStrategyAddress = _interestRateStrategyAddress;
        reserve.healthStrategyAddress = _healthStrategyAddress;
        reserve.optimalIncomeRatio = _optimalIncomeRatio;
        reserve.loanStrategyAddress = _loanStrategyAddress;
    }

    function getLiquidityRate(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) public view returns (uint256) {
        return reserve._getLiquidityRate(_tranche);
    }

    struct UpdateInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 juniorLiquidity;
        uint256 seniorLiquidity;
        uint256 liquidityRatio;
        uint256 totalDebt;
        // total liquidity rate
        uint256 newLiquidityRate;
        uint256 effectiveJuniorLiquidityRate;
        uint256 effectSeniorLiquidityRate;
        uint256 newBorrowRate;
        uint256 avgBorrowRate;
    }

    // for the purposes of updating interest rates, we only care about senior tranche liquidity.
    function updateInterestRates(
        DataTypes.ReserveData storage _reserve,
        address _reserveAddress,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorLiquidityAdded,
        uint256 _juniorLiquidityTaken,
        uint256 _seniorLiquidityAdded,
        uint256 _seniorLiquidityTaken,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) public {
        UpdateInterestRatesLocalVars memory vars;

        (vars.totalDebt, vars.avgBorrowRate) = (_totalDebt, _avgBorrowRate);

        (
            vars.newLiquidityRate,
            vars.newBorrowRate
        ) = IReserveInterestRateStrategy(_reserve.interestRateStrategyAddress)
            .calculateInterestRates(
                _reserveAddress,
                _seniorDepositTokenAddress,
                _seniorLiquidityAdded,
                _seniorLiquidityTaken,
                vars.totalDebt,
                vars.avgBorrowRate
            );
        require(
            vars.newLiquidityRate <= type(uint128).max,
            Errors.RL_LIQUIDITY_RATE_OVERFLOW
        );

        vars.seniorLiquidity = IERC20(_seniorDepositTokenAddress).totalSupply();
        vars.juniorLiquidity =
            IERC20(_juniorDepositTokenAddress).totalSupply() +
            _juniorLiquidityAdded -
            _juniorLiquidityTaken;

        if (vars.juniorLiquidity == 0) {
            vars.effectiveJuniorLiquidityRate = 0;
            vars.effectSeniorLiquidityRate = vars.newLiquidityRate;
        } else {
            vars.liquidityRatio = vars.seniorLiquidity.rayDiv(
                vars.juniorLiquidity
            );

            vars.effectiveJuniorLiquidityRate = vars
                .newLiquidityRate
                .rayMul(RAY - _reserve.optimalIncomeRatio)
                .rayMul(vars.liquidityRatio);

            vars.effectSeniorLiquidityRate = vars.newLiquidityRate.rayMul(
                _reserve.optimalIncomeRatio
            );
        }

        _reserve.currentOverallLiquidityRate = vars.newLiquidityRate;
        _reserve.currentJuniorLiquidityRate = vars.effectiveJuniorLiquidityRate;
        _reserve.currentSeniorLiquidityRate = vars.effectSeniorLiquidityRate;

        emit ReserveDataUpdated(
            _reserveAddress,
            vars.newLiquidityRate,
            vars.newBorrowRate
        );
    }

    function _getLiquidityRate(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) internal view returns (uint256) {
        if (_tranche == Tranche.JUNIOR) {
            return reserve.currentJuniorLiquidityRate;
        } else {
            return reserve.currentSeniorLiquidityRate;
        }
    }

    function trancheToBytes32(Tranche tranche) public view returns (bytes32) {
        return bytes32(uint256(tranche));
    }
}

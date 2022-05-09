// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import '../math/WadRayMath.sol';
import '../math/MathUtils.sol';
import '../types/DataTypes.sol';
import '../helpers/Errors.sol';
import '../../interfaces/IStableDebtToken.sol';
import '../../component/liquidity/DefaultReserveInterestRateStrategy.sol';
import 'hardhat/console.sol';

/**
 * @title ReserveLogic library
 * @author Voyager
 * @notice Implements the logic to update the reserves state
 **/
library ReserveLogic {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    uint256 internal constant RAY = 1e27;


    enum Tranche {
        JUNIOR,
        SENIOR
    }

    /**
     * @dev Emitted when the state of a reserve is updated
     * @param asset The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param liquidityIndex The new liquidity index
     **/
    event ReserveDataUpdated(
        address indexed asset,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 liquidityIndex
    );

    function init(
        DataTypes.ReserveData storage reserve,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress
    ) external {
        reserve.juniorLiquidityIndex = WadRayMath.ray();
        reserve.seniorLiquidityIndex = WadRayMath.ray();
        reserve.juniorDepositTokenAddress = _juniorDepositTokenAddress;
        reserve.seniorDepositTokenAddress = _seniorDepositTokenAddress;
        //reserve.currentOverallLiquidityRate = WadRayMath.ray();
        reserve.currentJuniorIncomeAllocation = _juniorIncomeAllocation;
        reserve.currentSeniorIncomeAllocation = _seniorIncomeAllocation;
        reserve.stableDebtAddress = _stableDebtAddress;
        reserve.interestRateStrategyAddress = _interestRateStrategyAddress;
        reserve.healthStrategyAddress = _healthStrategyAddress;
    }

    function updateState(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) public {
        _updateIndexes(reserve, _tranche);
    }

    function getLiquidityRate(
        DataTypes.ReserveData storage reserve,
        Tranche _tranche
    ) public view returns (uint256) {
        return getLiquidityRate(reserve, _tranche);
    }

    struct UpdateInterestRatesLocalVars {
        address debtTokenAddress;
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
        uint256 _seniorLiquidityAdded,
        uint256 _seniorLiquidityTaken
    ) public {
        UpdateInterestRatesLocalVars memory vars;

        vars.seniorLiquidity = IERC20(_seniorDepositTokenAddress).totalSupply();
        vars.juniorLiquidity = IERC20(_juniorDepositTokenAddress).totalSupply();
        // todo @xiaohuo check ray or wad
        vars.liquidityRatio = vars.seniorLiquidity.rayDiv(vars.juniorLiquidity);

        vars.debtTokenAddress = _reserve.stableDebtAddress;
        (vars.totalDebt, vars.avgBorrowRate) = IStableDebtToken(
            _reserve.stableDebtAddress
        ).getTotalSupplyAndAvgRate();

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
        require(
            vars.newBorrowRate <= type(uint128).max,
            Errors.RL_STABLE_BORROW_RATE_OVERFLOW
        );

        vars.effectiveJuniorLiquidityRate = vars
            .newLiquidityRate
            .rayMul(RAY - _reserve.optimalIncomeRatio)
            .rayMul(vars.liquidityRatio);

        vars.effectSeniorLiquidityRate = vars.newLiquidityRate.rayMul(
            _reserve.optimalIncomeRatio
        );

        _reserve.currentOverallLiquidityRate = vars.newLiquidityRate;
        _reserve.currentBorrowRate = vars.newBorrowRate;
        _reserve.currentJuniorLiquidityRate = vars.effectiveJuniorLiquidityRate;
        _reserve.currentSeniorLiquidityRate = vars.effectSeniorLiquidityRate;

        emit ReserveDataUpdated(
            _reserveAddress,
            vars.newLiquidityRate,
            vars.newBorrowRate,
            vars.newLiquidityRate
        );
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
                _getLiquidityRate(reserve, _tranche),
                timestamp
            )
            .rayMul(liquidityIndex);
        return cumulated;
    }

    function _getLiquidityRate(
        DataTypes.ReserveData storage _reserve,
        Tranche _tranche
    ) internal view returns (uint256) {
        if (_tranche == Tranche.JUNIOR) {
            return _reserve.currentJuniorLiquidityRate;
        } else {
            return _reserve.currentSeniorLiquidityRate;
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
            _updateJuniorLiquidityIndex(
                reserve,
                previousJuniorLiquidityIndex,
                uint40(lastJuniorUpdatedTimestamp)
            );
        } else {
            uint256 previousSeniorLiquidityIndex = reserve.seniorLiquidityIndex;
            uint256 lastSeniorUpdatedTimestamp = reserve
                .seniorLastUpdateTimestamp;
            _updateSeniorLiquidityIndex(
                reserve,
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
        uint256 juniorLiquidityRate = _getLiquidityRate(
            reserve,
            Tranche.JUNIOR
        );
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
        uint256 seniorLiquidityRate = _getLiquidityRate(
            reserve,
            Tranche.SENIOR
        );
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

    function trancheToBytes32(Tranche tranche) public view returns (bytes32) {
        return bytes32(uint256(tranche));
    }
}

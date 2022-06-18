// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Errors} from "./helpers/Errors.sol";
import {ReserveConfiguration} from "./configuration/ReserveConfiguration.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {ValidationLogic} from "./logic/ValidationLogic.sol";
import {LibAppStorage, AppStorage, ReserveData, ReserveConfigurationMap, BorrowData, BorrowState, Tranche} from "./LibAppStorage.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {WadRayMath} from "./math/WadRayMath.sol";
import "hardhat/console.sol";

library LibLiquidity {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using ReserveConfiguration for ReserveConfigurationMap;

    event ReserveDataUpdated(
        address indexed asset,
        uint256 liquidityRate,
        uint256 stableBorrowRate
    );

    struct DepositAndDebt {
        uint256 juniorDepositAmount;
        uint256 seniorDepositAmount;
        uint256 totalDebt;
        uint256 totalInterest;
        uint256 avgBorrowRate;
    }

    uint256 internal constant RAY = 1e27;

    /* --------------------------- reserve management --------------------------- */
    function init(
        ReserveData storage reserve,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        address _interestRateStrategyAddress,
        address _healthStrategyAddress,
        address _loanStrategyAddress,
        uint256 _optimalIncomeRatio
    ) internal {
        reserve.juniorDepositTokenAddress = _juniorDepositTokenAddress;
        reserve.seniorDepositTokenAddress = _seniorDepositTokenAddress;
        reserve.interestRateStrategyAddress = _interestRateStrategyAddress;
        reserve.healthStrategyAddress = _healthStrategyAddress;
        reserve.optimalIncomeRatio = _optimalIncomeRatio;
        reserve.loanStrategyAddress = _loanStrategyAddress;
        reserve.initialized = true;
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

    function updateInterestRates(
        address _reserveAddress,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorLiquidityAdded,
        uint256 _juniorLiquidityTaken,
        uint256 _seniorLiquidityAdded,
        uint256 _seniorLiquidityTaken,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) internal {
        UpdateInterestRatesLocalVars memory vars;
        ReserveData storage reserve = getReserveData(_reserveAddress);

        (vars.totalDebt, vars.avgBorrowRate) = (_totalDebt, _avgBorrowRate);

        (
            vars.newLiquidityRate,
            vars.newBorrowRate
        ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress)
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
                .rayMul(RAY - reserve.optimalIncomeRatio)
                .rayMul(vars.liquidityRatio);

            vars.effectSeniorLiquidityRate = vars.newLiquidityRate.rayMul(
                reserve.optimalIncomeRatio
            );
        }

        reserve.currentOverallLiquidityRate = vars.newLiquidityRate;
        reserve.currentJuniorLiquidityRate = vars.effectiveJuniorLiquidityRate;
        reserve.currentSeniorLiquidityRate = vars.effectSeniorLiquidityRate;

        emit ReserveDataUpdated(
            _reserveAddress,
            vars.newLiquidityRate,
            vars.newBorrowRate
        );
    }

    function _getLiquidityRate(ReserveData storage reserve, Tranche _tranche)
        internal
        view
        returns (uint256)
    {
        if (_tranche == Tranche.JUNIOR) {
            return reserve.currentJuniorLiquidityRate;
        } else {
            return reserve.currentSeniorLiquidityRate;
        }
    }

    /* ------------------------ state mutation functions ------------------------ */
    function updateStateOnDeposit(
        address _asset,
        Tranche _tranche,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData storage reserve = s._reserves[_asset];
        ValidationLogic.validateDeposit(reserve, _amount);
        if (Tranche.JUNIOR == _tranche) {
            updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                _amount,
                0,
                0,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        } else {
            updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                0,
                0,
                _amount,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        }
    }

    function updateStateOnWithdraw(
        address _asset,
        Tranche _tranche,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData storage reserve = s._reserves[_asset];
        if (Tranche.JUNIOR == _tranche) {
            updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                0,
                _amount,
                0,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        } else {
            updateInterestRates(
                _asset,
                reserve.juniorDepositTokenAddress,
                reserve.seniorDepositTokenAddress,
                0,
                0,
                0,
                0,
                _totalDebt,
                _avgBorrowRate
            );
        }
    }

    /* ----------------------------- view functions ----------------------------- */
    function getReserveData(address _asset)
        internal
        view
        returns (ReserveData storage)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._reserves[_asset];
    }

    function getReserveList() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address[] memory reserveList = new address[](s._reservesCount);
        for (uint256 i = 0; i < s._reservesCount; i++) {
            reserveList[i] = s._reserveList[i];
        }
        return reserveList;
    }

    function balance(
        address _reserve,
        address _user,
        Tranche _tranche
    ) internal view returns (uint256) {
        ReserveData memory reserve = getReserveData(_reserve);
        address vToken;
        if (Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
        } else {
            vToken = reserve.seniorDepositTokenAddress;
        }
        return IVToken(vToken).maxWithdraw(_user);
    }

    function unbonding(
        address _reserve,
        address _user,
        Tranche _tranche
    ) internal view returns (uint256) {
        ReserveData memory reserve = getReserveData(_reserve);
        address vToken;
        if (Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
        } else {
            vToken = reserve.seniorDepositTokenAddress;
        }
        (, uint256[] memory amounts) = IVToken(vToken).unbonding(_user);
        uint256 unbondingBalance = 0;
        for (uint8 i = 0; i < amounts.length; i++) {
            unbondingBalance += amounts[i];
        }
        return unbondingBalance;
    }

    function getDepositAndDebt(address _reserve)
        internal
        view
        returns (DepositAndDebt memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData storage reserve = s._reserves[_reserve];
        BorrowState storage borrowState = s._borrowState[_reserve];

        DepositAndDebt memory res;
        res.juniorDepositAmount = IVToken(reserve.juniorDepositTokenAddress)
            .totalAssets();
        res.seniorDepositAmount = IVToken(reserve.seniorDepositTokenAddress)
            .totalAssets();
        (res.totalDebt, res.totalInterest, res.avgBorrowRate) = (
            borrowState.totalDebt,
            borrowState.totalInterest,
            borrowState.avgBorrowRate
        );
        return res;
    }

    function getLiquidityRate(address _asset, Tranche _tranche)
        internal
        view
        returns (uint256)
    {
        ReserveData memory reserve = getReserveData(_asset);
        if (_tranche == Tranche.JUNIOR) {
            return reserve.currentJuniorLiquidityRate;
        } else {
            return reserve.currentSeniorLiquidityRate;
        }
    }

    function getConfiguration(address _asset)
        internal
        view
        returns (ReserveConfigurationMap memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._reserves[_asset].configuration;
    }

    function getFlags(address _asset)
        internal
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        ReserveConfigurationMap memory currentConfig = getConfiguration(_asset);
        return currentConfig.getFlags();
    }

    function utilizationRate(address _reserve) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData memory reserve = getReserveData(_reserve);
        BorrowState memory borrowState = s._borrowState[_reserve];
        uint256 totalDebt = borrowState.totalDebt.add(
            borrowState.totalInterest
        );

        uint256 totalPendingWithdrawal = IVToken(
            reserve.seniorDepositTokenAddress
        ).totalUnbonding();

        uint256 availableLiquidity = IERC20(_reserve).balanceOf(
            reserve.seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        return
            totalDebt == 0
                ? 0
                : totalDebt.rayDiv(availableLiquidity.add(totalDebt));
    }
}

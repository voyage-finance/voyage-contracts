// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {LibReserveConfiguration} from "./LibReserveConfiguration.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {ValidationLogic} from "./LibValidation.sol";
import {LibAppStorage, AppStorage, ReserveData, ReserveConfigurationMap, BorrowData, BorrowState, Tranche} from "./LibAppStorage.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {VToken} from "../tokenization/VToken.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";

library LibLiquidity {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

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
    uint256 internal constant UINT256_MAX = type(uint256).max;

    /* --------------------------- reserve management --------------------------- */
    function init(
        ReserveData storage reserve,
        address _asset,
        address _interestRateStrategyAddress,
        address _priceOracle,
        address _nftAddr
    ) internal {
        require(
            reserve.seniorDepositTokenAddress == address(0) &&
                reserve.juniorDepositTokenAddress == address(0),
            "deposit tokens already deployed"
        );
        AppStorage storage s = LibAppStorage.diamondStorage();
        IERC20Metadata token = IERC20Metadata(_asset);
        ReserveConfigurationMap memory config = s
            ._reserves[_asset]
            .configuration;
        config.setDecimals(token.decimals());
        LibReserveConfiguration.saveConfiguration(_asset, config);
        bytes memory data = abi.encodeWithSelector(
            VToken.initialize.selector,
            address(this),
            _asset
        );
        reserve.seniorDepositTokenAddress = deployBeaconProxy(
            address(s.seniorDepositTokenBeacon),
            data
        );
        token.approve(reserve.seniorDepositTokenAddress, UINT256_MAX);
        reserve.juniorDepositTokenAddress = deployBeaconProxy(
            address(s.juniorDepositTokenBeacon),
            data
        );
        token.approve(reserve.juniorDepositTokenAddress, UINT256_MAX);
        reserve.interestRateStrategyAddress = _interestRateStrategyAddress;
        reserve.initialized = true;
        reserve.priceOracle = _priceOracle;
        reserve.nftAddress = _nftAddr;
    }

    function deployBeaconProxy(address _impl, bytes memory _data)
        internal
        returns (address)
    {
        return address(new BeaconProxy(_impl, _data));
    }

    struct UpdateInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 juniorLiquidity;
        uint256 seniorLiquidity;
        uint256 liquidityRatio;
        uint256 totalDebt;
        // total liquidity rate
        uint256 incomeRatio;
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
        require(vars.newLiquidityRate <= type(uint128).max);

        vars.incomeRatio = LibReserveConfiguration
            .getConfiguration(_reserveAddress)
            .getIncomeRatio();
        vars.seniorLiquidity = IERC20Metadata(_seniorDepositTokenAddress)
            .totalSupply();
        vars.juniorLiquidity =
            IERC20Metadata(_juniorDepositTokenAddress).totalSupply() +
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
                .rayMul(1e4 - vars.incomeRatio)
                .rayMul(vars.liquidityRatio);

            vars.effectSeniorLiquidityRate = vars.newLiquidityRate.percentMul(
                vars.incomeRatio
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

    /* --------------------------- fee management --------------------------- */
    function updateProtocolFee(address _treasuryAddr, uint256 _cutRatio)
        internal
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.protocolFee.treasuryAddress = _treasuryAddr;
        s.protocolFee.cutRatio = _cutRatio;
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
    function getProtocolFee() internal view returns (address, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.protocolFee.treasuryAddress, s.protocolFee.cutRatio);
    }

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
        for (uint256 i = 0; i < s._reservesCount; ) {
            reserveList[i] = s._reserveList[i];
            unchecked {
                ++i;
            }
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
        for (uint8 i = 0; i < amounts.length; ) {
            unbondingBalance += amounts[i];
            unchecked {
                ++i;
            }
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

    function utilizationRate(address _reserve) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData memory reserve = getReserveData(_reserve);
        BorrowState memory borrowState = s._borrowState[_reserve];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;

        uint256 totalPendingWithdrawal = IVToken(
            reserve.seniorDepositTokenAddress
        ).totalUnbonding();

        uint256 availableLiquidity = IERC20Metadata(_reserve).balanceOf(
            reserve.seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        return
            totalDebt == 0
                ? 0
                : totalDebt.rayDiv(availableLiquidity + totalDebt);
    }
}

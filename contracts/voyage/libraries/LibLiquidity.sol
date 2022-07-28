// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {LibReserveConfiguration} from "./LibReserveConfiguration.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {LibAppStorage, AppStorage, ReserveData, ReserveConfigurationMap, BorrowData, BorrowState, Tranche} from "./LibAppStorage.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {IWETH9} from "../../shared/facets/PaymentsFacet.sol";
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
        address currency;
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
        address _currency,
        address _interestRateStrategyAddress,
        address _priceOracle
    ) internal {
        require(
            reserve.seniorDepositTokenAddress == address(0) &&
                reserve.juniorDepositTokenAddress == address(0),
            "deposit tokens already deployed"
        );
        AppStorage storage s = LibAppStorage.diamondStorage();
        IERC20Metadata token = IERC20Metadata(_currency);
        ReserveConfigurationMap memory config = reserve.configuration;
        config.setDecimals(token.decimals());
        reserve.configuration = config;
        // LibReserveConfiguration.saveConfiguration(_currency, config);
        bytes memory data = abi.encodeWithSelector(
            VToken.initialize.selector,
            address(this),
            _currency
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
        reserve.currency = _currency;
    }

    function deployBeaconProxy(address _impl, bytes memory _data)
        internal
        returns (address)
    {
        return address(new BeaconProxy(_impl, _data));
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

    function updateWETH9(address _weth9) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.WETH9 = IWETH9(_weth9);
    }

    /* ----------------------------- view functions ----------------------------- */
    function getProtocolFee() internal view returns (address, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.protocolFee.treasuryAddress, s.protocolFee.cutRatio);
    }

    function getReserveData(address _collection)
        internal
        view
        returns (ReserveData storage)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._reserveData[_collection];
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
        address _collection,
        address _user,
        Tranche _tranche
    ) internal view returns (uint256) {
        ReserveData memory reserve = getReserveData(_collection);
        address vToken;
        if (Tranche.JUNIOR == _tranche) {
            vToken = reserve.juniorDepositTokenAddress;
        } else {
            vToken = reserve.seniorDepositTokenAddress;
        }
        return IVToken(vToken).maxWithdraw(_user);
    }

    function unbonding(
        address _collection,
        address _user,
        Tranche _tranche
    ) internal view returns (uint256) {
        ReserveData memory reserve = getReserveData(_collection);
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

    function getDepositAndDebt(address _collection)
        internal
        view
        returns (DepositAndDebt memory)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData storage reserve = s._reserveData[_collection];
        BorrowState storage borrowState = s._borrowState[reserve.currency];

        DepositAndDebt memory res;
        res.currency = reserve.currency;
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

    function utilizationRate(address _collection)
        internal
        view
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData memory reserve = getReserveData(_collection);
        BorrowState memory borrowState = s._borrowState[reserve.currency];
        uint256 totalDebt = borrowState.totalDebt + borrowState.totalInterest;

        uint256 totalPendingWithdrawal = IVToken(
            reserve.seniorDepositTokenAddress
        ).totalUnbonding();

        uint256 availableLiquidity = IERC20Metadata(reserve.currency).balanceOf(
            reserve.seniorDepositTokenAddress
        ) - totalPendingWithdrawal;

        return
            totalDebt == 0
                ? 0
                : totalDebt.rayDiv(availableLiquidity + totalDebt);
    }
}

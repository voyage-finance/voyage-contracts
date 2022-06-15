// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, AppStorage, ReserveData, BorrowState, Tranche} from "./LibAppStorage.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Errors} from "./helpers/Errors.sol";
import {ReserveLogic} from "./logic/ReserveLogic.sol";
import {ValidationLogic} from "./logic/ValidationLogic.sol";

library LibLiquidity {
    using ReserveLogic for ReserveData;

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
            reserve.updateInterestRates(
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
            reserve.updateInterestRates(
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
            reserve.updateInterestRates(
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
            reserve.updateInterestRates(
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
}

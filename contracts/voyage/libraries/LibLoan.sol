// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LibAppStorage, AppStorage, BorrowData, BorrowState, DrawDown, PMT, RepaymentData, ReserveData, RepaymentData} from "./LibAppStorage.sol";
import {LibLiquidity} from "./LibLiquidity.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {MathUtils} from "../../shared/libraries/MathUtils.sol";

library LibLoan {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant SECOND_PER_MONTH = 30 days;

    struct DebtDetail {
        uint256 principal;
        uint256 term;
        uint256 epoch;
        uint256 nper;
        address reserve;
        PMT pmt;
        uint256 apr;
        uint256 borrowAt;
        uint256 nextPaymentDue;
        uint256 totalPrincipalPaid;
        uint256 totalInterestPaid;
        uint256 paidTimes;
    }

    /* ----------------------------- state mutations ---------------------------- */

    function insertDebt(
        address _reserve,
        address _vault,
        uint256 _principal,
        uint256 _term,
        uint256 _epoch,
        uint256 _apr
    ) internal returns (uint256 drawdownId, DrawDown storage) {
        BorrowState storage borrowState = getBorrowState(_reserve);
        BorrowData storage borrowData = getBorrowData(_reserve, _vault);
        uint256 currentDrawDownNumber = borrowData.nextDrawDownNumber;
        DrawDown storage dd = borrowData.drawDowns[currentDrawDownNumber];
        dd.principal = _principal;
        dd.term = _term;
        dd.epoch = _epoch;
        dd.apr = _apr;
        dd.nper = _term.div(_epoch);
        dd.borrowAt = block.timestamp;

        uint256 principalRay = _principal.wadToRay();
        uint256 interestRay = principalRay.rayMul(_apr);
        uint256 interest = interestRay.rayToWad();
        dd.interest = interest;

        PMT memory pmt;
        pmt.principal = _principal.div(dd.nper);
        pmt.interest = interestRay.rayToWad().div(dd.nper);
        pmt.pmt = pmt.principal.add(pmt.interest);
        dd.pmt = pmt;

        dd.nextPaymentDue = dd.borrowAt.add(
            dd.nper.sub(dd.paidTimes).mul(dd.epoch.mul(SECOND_PER_MONTH))
        );

        borrowData.nextDrawDownNumber++;
        borrowData.mapSize++;
        borrowData.totalPrincipal = borrowData.totalPrincipal.add(_principal);
        borrowData.totalInterest = borrowData.totalInterest.add(
            interestRay.rayToWad()
        );

        uint256 totalDebtRay = borrowState.totalDebt.wadToRay();
        borrowState.avgBorrowRate = totalDebtRay
            .rayMul(borrowState.avgBorrowRate)
            .add(principalRay.rayMul(_apr))
            .rayDiv(totalDebtRay.add(principalRay));
        borrowState.totalDebt = borrowState.totalDebt.add(
            principalRay.rayToWad()
        );
        borrowState.totalInterest = borrowState.totalInterest.add(
            interestRay.rayToWad()
        );

        return (currentDrawDownNumber, dd);
    }

    function repay(
        address underlying,
        address vault,
        uint256 drawDownNumber,
        uint256 principal,
        uint256 interest,
        bool isLiquidated
    ) internal {
        BorrowData storage debtData = getBorrowData(underlying, vault);
        BorrowState storage borrowStat = getBorrowState(underlying);
        DrawDown storage dd = debtData.drawDowns[drawDownNumber];
        dd.paidTimes += 1;
        if (dd.paidTimes == dd.nper) {
            delete debtData.drawDowns[drawDownNumber];
        } else {
            dd.totalPrincipalPaid = dd.totalPrincipalPaid.add(principal);
            dd.totalInterestPaid = dd.totalInterestPaid.add(interest);
            RepaymentData memory repayment;
            repayment.interest = interest;
            repayment.principal = principal;
            repayment.total = principal.add(interest);
            repayment.paidAt = uint40(block.timestamp);
            dd.repayments.push(repayment);
            dd.nextPaymentDue = dd.borrowAt.add(
                dd.nper.sub(dd.paidTimes).mul(dd.epoch.mul(SECOND_PER_MONTH))
            );
        }

        debtData.totalPrincipal = debtData.totalPrincipal.sub(principal);
        debtData.totalInterest = debtData.totalInterest.sub(interest);
        debtData.totalPaid = debtData.totalPaid.add(principal);
        uint256 interestRay = interest.wadToRay();
        uint256 principalRay = principal.wadToRay();

        uint256 totalDebtRay = borrowStat.totalDebt.wadToRay();
        borrowStat.avgBorrowRate = totalDebtRay
            .rayMul(borrowStat.avgBorrowRate)
            .sub(principalRay.rayMul(dd.apr))
            .rayDiv(totalDebtRay.sub(principalRay));
        borrowStat.totalDebt = borrowStat.totalDebt.sub(
            principalRay.rayToWad()
        );
        borrowStat.totalInterest = borrowStat.totalInterest.sub(
            interestRay.rayToWad()
        );
    }

    function updateStateOnBorrow(
        address _asset,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData storage reserve = s._reserves[_asset];
        LibLiquidity.updateInterestRates(
            _asset,
            reserve.juniorDepositTokenAddress,
            reserve.seniorDepositTokenAddress,
            0,
            0,
            0,
            _amount,
            _totalDebt,
            _avgBorrowRate
        );
    }

    function updateStateOnRepayment(
        address _asset,
        uint256 _amount,
        uint256 _totalDebt,
        uint256 _avgBorrowRate
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ReserveData storage reserve = s._reserves[_asset];
        LibLiquidity.updateInterestRates(
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

    /* ----------------------------- view functions ----------------------------- */

    function getBorrowState(address _underlying)
        internal
        view
        returns (BorrowState storage)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._borrowState[_underlying];
    }

    function getBorrowData(address _underlying, address _vault)
        internal
        view
        returns (BorrowData storage)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._borrowData[_underlying][_vault];
    }

    function getDrawDownDetail(
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) internal view returns (DebtDetail memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        DrawDown storage dd = borrowData.drawDowns[_drawDownId];
        DebtDetail memory debtDetail;
        debtDetail.principal = dd.principal;
        debtDetail.term = dd.term;
        debtDetail.epoch = dd.epoch;
        debtDetail.nper = dd.nper;
        debtDetail.pmt = dd.pmt;
        debtDetail.apr = dd.apr;
        debtDetail.borrowAt = dd.borrowAt;
        debtDetail.nextPaymentDue = dd.nextPaymentDue;
        debtDetail.totalInterestPaid = dd.totalInterestPaid;
        debtDetail.totalPrincipalPaid = dd.totalPrincipalPaid;
        debtDetail.paidTimes = dd.paidTimes;
        debtDetail.reserve = _reserve;
        return debtDetail;
    }

    function getRepayment(
        address _reserve,
        address _vault,
        uint256 _drawDownId
    ) internal view returns (RepaymentData[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        DrawDown storage dd = borrowData.drawDowns[_drawDownId];
        return dd.repayments;
    }

    function getDrawDownList(address _reserve, address _vault)
        internal
        view
        returns (uint256, uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_reserve][_vault];
        return (borrowData.paidDrawDownNumber, borrowData.nextDrawDownNumber);
    }

    function getPMT(
        address _reserve,
        address _vault,
        uint256 _drawDown
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        DrawDown storage dd = s._borrowData[_reserve][_vault].drawDowns[
            _drawDown
        ];
        return (dd.pmt.principal, dd.pmt.interest);
    }
}

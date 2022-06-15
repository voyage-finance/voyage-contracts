// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";
import {DefaultReserveInterestRateStrategy} from "../../component/liquidity/DefaultReserveInterestRateStrategy.sol";

/**
 * @title DebtLogic library
 * @author Voyage
 * @notice Implements the logic to update the debt state
 **/
library DebtLogic {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant SECOND_PER_MONTH = 30 days;

    using DebtLogic for DataTypes.BorrowData;
    using DebtLogic for DataTypes.BorrowStat;

    function insertDrawDown(
        DataTypes.BorrowData storage debtData,
        DataTypes.BorrowStat storage borrowStat,
        uint256 principal,
        uint256 term,
        uint256 epoch,
        uint256 apr
    ) public {
        uint256 currentDrawDownNumber = debtData.nextDrawDownNumber;
        DataTypes.DrawDown storage dd = debtData.drawDowns[
            currentDrawDownNumber
        ];
        dd.principal = principal;
        dd.term = term;
        dd.epoch = epoch;
        dd.apr = apr;
        dd.nper = term.div(epoch);
        dd.borrowAt = block.timestamp;

        uint256 principalRay = principal.wadToRay();
        uint256 interestRay = principalRay.rayMul(apr);

        DataTypes.PMT memory pmt;
        pmt.principal = principal.div(dd.nper);
        pmt.interest = interestRay.rayToWad().div(dd.nper);
        pmt.pmt = pmt.principal.add(pmt.interest);
        dd.pmt = pmt;

        dd.nextPaymentDue = dd.borrowAt.add(
            dd.nper.sub(dd.paidTimes).mul(dd.epoch.mul(SECOND_PER_MONTH))
        );
        debtData.nextDrawDownNumber++;
        debtData.mapSize++;
        debtData.totalPrincipal = debtData.totalPrincipal.add(principal);
        debtData.totalInterest = debtData.totalInterest.add(
            interestRay.rayToWad()
        );
        borrowStat.increase(principalRay, interestRay, apr);
    }

    function getDrawDownPeriod(DataTypes.BorrowData storage debtData)
        public
        view
        returns (uint256, uint256)
    {
        return (debtData.paidDrawDownNumber, debtData.nextDrawDownNumber);
    }

    function getDrawDownDetail(
        DataTypes.BorrowData storage debtData,
        uint256 _drawDownId
    ) public view returns (DataTypes.DebtDetail memory) {
        DataTypes.DrawDown storage dd = debtData.drawDowns[_drawDownId];
        DataTypes.DebtDetail memory debtDetail;
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
        return debtDetail;
    }

    function repay(
        DataTypes.BorrowData storage debtData,
        DataTypes.BorrowStat storage borrowStat,
        uint256 drawDownNumber,
        uint256 principal,
        uint256 interest,
        bool isLiquidated
    ) public {
        DataTypes.DrawDown storage dd = debtData.drawDowns[drawDownNumber];
        dd.paidTimes += 1;
        if (dd.paidTimes == dd.nper) {
            delete debtData.drawDowns[drawDownNumber];
        } else {
            dd.totalPrincipalPaid = dd.totalPrincipalPaid.add(principal);
            dd.totalInterestPaid = dd.totalInterestPaid.add(interest);
            DataTypes.RepaymentData memory repayment;
            repayment.interest = interest;
            repayment.principal = principal;
            repayment.total = principal.add(interest);
            repayment.paidAt = uint40(block.timestamp);
            dd.repayments.push(repayment);
            dd.nextPaymentDue = dd.borrowAt.add(
                dd.nper.sub(dd.paidTimes).mul(dd.epoch.mul(SECOND_PER_MONTH))
            );
        }

        debtData.totalPrincipal.sub(principal);
        debtData.totalInterest.sub(interest);
        uint256 interestRay = interest.wadToRay();
        borrowStat.decrease(principal.wadToRay(), interestRay, dd.apr);
    }

    function increase(
        DataTypes.BorrowStat storage borrowStat,
        uint256 principalPay,
        uint256 interestRay,
        uint256 rate
    ) internal {
        uint256 totalDebtRay = borrowStat.totalDebt.wadToRay();
        borrowStat.avgBorrowRate = totalDebtRay
            .rayMul(borrowStat.avgBorrowRate)
            .add(principalPay.rayMul(rate))
            .rayDiv(totalDebtRay.add(principalPay));
        borrowStat.totalDebt = borrowStat.totalDebt.add(
            principalPay.rayToWad()
        );
        borrowStat.totalInterest = borrowStat.totalInterest.add(
            interestRay.rayToWad()
        );
    }

    function decrease(
        DataTypes.BorrowStat storage borrowStat,
        uint256 principalPay,
        uint256 interestRay,
        uint256 rate
    ) internal {
        uint256 totalDebtRay = borrowStat.totalDebt.wadToRay();
        borrowStat.avgBorrowRate = totalDebtRay
            .rayMul(borrowStat.avgBorrowRate)
            .sub(principalPay.rayMul(rate))
            .rayDiv(totalDebtRay.sub(principalPay));
        borrowStat.totalDebt = borrowStat.totalDebt.sub(
            principalPay.rayToWad()
        );
        borrowStat.totalInterest = borrowStat.totalInterest.sub(
            interestRay.rayToWad()
        );
    }
}

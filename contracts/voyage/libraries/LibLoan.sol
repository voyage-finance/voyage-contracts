// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, AppStorage, BorrowData, BorrowState, Loan, PMT, RepaymentData, ReserveData, RepaymentData} from "./LibAppStorage.sol";
import {LibLiquidity} from "./LibLiquidity.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";

library LibLoan {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant SECOND_PER_DAY = 1 days;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    struct LoanDetail {
        uint256 principal;
        uint256 interest;
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
        address _collection,
        address _currency,
        address _vault,
        uint256 _principal,
        uint256 _term,
        uint256 _epoch,
        uint256 _apr
    ) internal returns (uint256 loanId, Loan storage) {
        BorrowState storage borrowState = getBorrowState(_currency);
        BorrowData storage borrowData = getBorrowData(
            _collection,
            _currency,
            _vault
        );
        uint256 currentLoanNumber = borrowData.nextLoanNumber;
        Loan storage loan = borrowData.loans[currentLoanNumber];
        loan.principal = _principal;
        loan.term = _term;
        loan.epoch = _epoch;
        loan.apr = _apr;
        loan.nper = (_term * SECOND_PER_DAY) / (_epoch * SECOND_PER_DAY);
        loan.borrowAt = block.timestamp;
        uint256 periodsPerYear = SECONDS_PER_YEAR /
            (loan.epoch * SECOND_PER_DAY);
        // eir = (apr * nper ) / periods_per_year
        uint256 effectiveInterestRate = (loan.apr * loan.nper) / periodsPerYear;
        loan.interest = loan.principal.rayMul(effectiveInterestRate);

        PMT memory pmt;
        pmt.principal = loan.principal / loan.nper;
        pmt.interest = loan.interest / loan.nper;
        pmt.pmt = pmt.principal + pmt.interest;
        loan.pmt = pmt;

        loan.nextPaymentDue =
            loan.borrowAt +
            (loan.paidTimes + 1) *
            loan.epoch *
            SECOND_PER_DAY;

        borrowData.nextLoanNumber++;
        borrowData.mapSize++;
        borrowData.totalPrincipal = borrowData.totalPrincipal + _principal;
        borrowData.totalInterest = borrowData.totalInterest + loan.interest;

        /// @dev most of the time, principal and totalDebt are denominated in wad
        /// we use ray operations as we are seeking avgBorrowRate, which is supposed to be epxressed in ray.
        /// in the vast majority of cases, as the underlying asset has 18 DPs, we end up just padding the LSBs with 0 to make avgBorrowRate a ray.
        ///  formula: ((debt * avgBorrowRate) + (principal*apr)) / (debt + principal)
        uint256 numer = (
            borrowState.totalDebt.rayMul(borrowState.avgBorrowRate)
        ) + (loan.principal.rayMul(loan.apr));
        uint256 denom = borrowState.totalDebt + loan.principal;
        borrowState.avgBorrowRate = numer.rayDiv(denom);
        borrowState.totalDebt = borrowState.totalDebt + loan.principal;
        borrowState.totalInterest = borrowState.totalInterest + loan.interest;

        return (currentLoanNumber, loan);
    }

    function repay(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanNumber,
        uint256 _principal,
        uint256 _interest
    ) internal returns (uint256, bool) {
        bool isFinal = false;
        BorrowData storage debtData = getBorrowData(
            _collection,
            _currency,
            _vault
        );
        BorrowState storage borrowState = getBorrowState(_currency);
        Loan storage loan = debtData.loans[_loanNumber];
        loan.paidTimes += 1;
        if (loan.paidTimes == loan.nper) {
            delete debtData.loans[_loanNumber];
            isFinal = true;
        } else {
            loan.totalPrincipalPaid = loan.totalPrincipalPaid + _principal;
            loan.totalInterestPaid = loan.totalInterestPaid + _interest;
            RepaymentData memory repayment;
            repayment.interest = _interest;
            repayment.principal = _principal;
            repayment.total = _principal + _interest;
            repayment.paidAt = uint40(block.timestamp);
            loan.repayments.push(repayment);
            loan.nextPaymentDue =
                loan.borrowAt +
                (loan.paidTimes + 1) *
                loan.epoch *
                SECOND_PER_DAY;
        }

        debtData.totalPrincipal = debtData.totalPrincipal - _principal;
        debtData.totalInterest = debtData.totalInterest - _interest;
        debtData.totalPaid = debtData.totalPaid + _principal;
        if (borrowState.totalDebt == _principal) {
            borrowState.avgBorrowRate = 0;
        } else {
            uint256 numer = borrowState.totalDebt.rayMul(
                borrowState.avgBorrowRate
            ) - _principal.rayMul(loan.apr);
            uint256 denom = borrowState.totalDebt - _principal;
            borrowState.avgBorrowRate = numer.rayDiv(denom);
        }
        borrowState.totalDebt = borrowState.totalDebt - _principal;
        borrowState.totalInterest = borrowState.totalInterest - _interest;

        return (
            loan.repayments.length == 0 ? 0 : loan.repayments.length - 1,
            isFinal
        );
    }

    /* ----------------------------- view functions ----------------------------- */

    function getBorrowState(address _currency)
        internal
        view
        returns (BorrowState storage)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._borrowState[_currency];
    }

    function getBorrowData(
        address _collection,
        address _currency,
        address _vault
    ) internal view returns (BorrowData storage) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._borrowData[_collection][_currency][_vault];
    }

    function getLoanDetail(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanId
    ) internal view returns (LoanDetail memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        Loan storage loan = borrowData.loans[_loanId];
        LoanDetail memory loanDetail;
        loanDetail.principal = loan.principal;
        loanDetail.interest = loan.interest;
        loanDetail.term = loan.term;
        loanDetail.epoch = loan.epoch;
        loanDetail.nper = loan.nper;
        loanDetail.pmt = loan.pmt;
        loanDetail.apr = loan.apr;
        loanDetail.borrowAt = loan.borrowAt;
        loanDetail.nextPaymentDue = loan.nextPaymentDue;
        loanDetail.totalInterestPaid = loan.totalInterestPaid;
        loanDetail.totalPrincipalPaid = loan.totalPrincipalPaid;
        loanDetail.paidTimes = loan.paidTimes;
        loanDetail.reserve = _currency;
        return loanDetail;
    }

    function getRepayment(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanId
    ) internal view returns (RepaymentData[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        Loan storage loan = borrowData.loans[_loanId];
        return loan.repayments;
    }

    function getLoanList(
        address _collection,
        address _currency,
        address _vault
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        return (borrowData.paidLoanNumber, borrowData.nextLoanNumber);
    }

    function getPMT(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loan
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Loan storage loan = s._borrowData[_collection][_currency][_vault].loans[
            _loan
        ];
        return (loan.pmt.principal, loan.pmt.interest);
    }
}

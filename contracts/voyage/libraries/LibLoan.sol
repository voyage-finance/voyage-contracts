// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, AppStorage, BorrowData, BorrowState, Loan, PMT, RepaymentData, ReserveData, RepaymentData, NFTInfo} from "./LibAppStorage.sol";
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

    struct ExecuteDebtParam {
        address collection;
        address currency;
        uint256 tokenId;
        address vault;
        uint256 principal;
        uint256 interest;
        uint256 term;
        uint256 epoch;
        uint256 apr;
    }

    /* ----------------------------- state mutations ---------------------------- */

    function releaseLien(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanId
    ) internal returns (bool success, uint256 tokenId) {
        BorrowData storage borrowData = getBorrowData(
            _collection,
            _currency,
            _vault
        );

        Loan storage loan = borrowData.loans[_loanId];
        uint256[] storage collaterals = loan.collateral;
        if (collaterals.length == 0) {
            success = false;
            return (success, tokenId);
        }

        if (collaterals.length == 1) {
            success = true;
            tokenId = collaterals[0];
            collaterals.pop();
            delete LibAppStorage.ds().nftIndex[_collection][tokenId];
            return (success, tokenId);
        }

        (collaterals[0], collaterals[collaterals.length - 1]) = (
            collaterals[collaterals.length - 1],
            collaterals[0]
        );
        tokenId = collaterals[collaterals.length - 1];
        collaterals.pop();
        delete LibAppStorage.ds().nftIndex[_collection][tokenId];
        return (success, tokenId);
    }

    function insertDebt(
        address _collection,
        address _currency,
        uint256 _collateral,
        address _vault,
        uint256 _principal,
        uint256 _term,
        uint256 _epoch,
        uint256 _apr
    ) internal returns (uint256 loanId, Loan storage) {
        ExecuteDebtParam memory param;
        param.collection = _collection;
        param.currency = _currency;
        param.tokenId = _collateral;
        param.vault = _vault;
        param.principal = _principal;
        param.term = _term;
        param.epoch = _epoch;
        param.apr = _apr;
        BorrowState storage borrowState = getBorrowState(
            param.collection,
            param.currency
        );
        BorrowData storage borrowData = getBorrowData(
            param.collection,
            param.currency,
            param.vault
        );
        uint256 currentLoanNumber = borrowData.nextLoanNumber;
        Loan storage loan = borrowData.loans[currentLoanNumber];
        loan.principal = param.principal;
        loan.term = param.term;
        loan.epoch = param.epoch;
        loan.apr = param.apr;
        loan.nper = (_term * SECOND_PER_DAY) / (_epoch * SECOND_PER_DAY);
        loan.borrowAt = block.timestamp;
        uint256 periodsPerYear = SECONDS_PER_YEAR /
            (loan.epoch * SECOND_PER_DAY);
        uint256 effectiveInterestRate = (loan.apr * loan.nper) / periodsPerYear;
        loan.interest = loan.principal.rayMul(effectiveInterestRate);

        PMT memory pmt;
        pmt.principal = loan.principal / loan.nper;
        pmt.interest = loan.interest / loan.nper;
        pmt.pmt = pmt.principal + pmt.interest;
        loan.pmt = pmt;
        loan.collateral.push(param.tokenId);
        NFTInfo memory nftInfo;
        nftInfo.collection = param.collection;
        nftInfo.tokenId = param.tokenId;
        nftInfo.currency = param.currency;
        nftInfo.price = param.principal;
        nftInfo.isCollateral = true;
        LibAppStorage.ds().nftIndex[param.collection][param.tokenId] = nftInfo;
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
        ExecuteDebtParam memory param;
        param.collection = _collection;
        param.currency = _currency;
        param.vault = _vault;
        param.principal = _principal;
        param.interest = _interest;
        bool isFinal = false;
        BorrowData storage debtData = getBorrowData(
            param.collection,
            param.currency,
            param.vault
        );
        BorrowState storage borrowState = getBorrowState(
            param.collection,
            param.currency
        );
        Loan storage loan = debtData.loans[_loanNumber];
        loan.paidTimes += 1;
        if (loan.paidTimes == loan.nper) {
            uint256[] storage collaterals = loan.collateral;
            for (uint256 i = 0; i < collaterals.length; i++) {
                LibAppStorage
                .ds()
                .nftIndex[param.collection][collaterals[i]]
                    .isCollateral = false;
            }
            delete debtData.loans[_loanNumber];
            isFinal = true;
            borrowState.numRepaidLoans[param.vault].repaidTimes =
                borrowState.numRepaidLoans[param.vault].repaidTimes +
                1;
        } else {
            loan.totalPrincipalPaid = loan.totalPrincipalPaid + param.principal;
            loan.totalInterestPaid = loan.totalInterestPaid + param.interest;
            RepaymentData memory repayment;
            repayment.interest = param.interest;
            repayment.principal = param.principal;
            repayment.total = param.principal + param.interest;
            repayment.paidAt = uint40(block.timestamp);
            loan.repayments.push(repayment);
            // t, t+1, t+2
            loan.nextPaymentDue =
                loan.borrowAt +
                loan.paidTimes *
                loan.epoch *
                SECOND_PER_DAY;
        }

        debtData.totalPrincipal = debtData.totalPrincipal - param.principal;
        debtData.totalInterest = debtData.totalInterest - param.interest;
        if (borrowState.totalDebt == param.principal) {
            borrowState.avgBorrowRate = 0;
        } else {
            uint256 numer = borrowState.totalDebt.rayMul(
                borrowState.avgBorrowRate
            ) - param.principal.rayMul(loan.apr);
            uint256 denom = borrowState.totalDebt - param.principal;
            borrowState.avgBorrowRate = numer.rayDiv(denom);
        }
        borrowState.totalDebt = borrowState.totalDebt - param.principal;
        borrowState.totalInterest = borrowState.totalInterest - param.interest;

        return (
            loan.repayments.length == 0 ? 0 : loan.repayments.length - 1,
            isFinal
        );
    }

    /* ----------------------------- view functions ----------------------------- */

    function getBorrowState(address _collection, address _currency)
        internal
        view
        returns (BorrowState storage)
    {
        AppStorage storage s = LibAppStorage.ds();
        return s._borrowState[_collection][_currency];
    }

    function getBorrowData(
        address _collection,
        address _currency,
        address _vault
    ) internal view returns (BorrowData storage) {
        AppStorage storage s = LibAppStorage.ds();
        return s._borrowData[_collection][_currency][_vault];
    }

    function getLoanDetail(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanId
    ) internal view returns (LoanDetail memory) {
        AppStorage storage s = LibAppStorage.ds();
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
        AppStorage storage s = LibAppStorage.ds();
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
        AppStorage storage s = LibAppStorage.ds();
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
        AppStorage storage s = LibAppStorage.ds();
        Loan storage loan = s._borrowData[_collection][_currency][_vault].loans[
            _loan
        ];
        return (loan.pmt.principal, loan.pmt.interest);
    }
}

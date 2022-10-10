// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AssetInfo} from "../interfaces/IMarketPlaceAdapter.sol";
import {LibAppStorage, AppStorage, BorrowData, BorrowState, Loan, PMT, RepaymentData, ReserveData, RepaymentData, NFTInfo, ReserveConfigurationMap} from "./LibAppStorage.sol";
import {LibLiquidity} from "./LibLiquidity.sol";
import {LibReserveConfiguration} from "./LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {IVault} from "../../vault/Vault.sol";

struct ExecuteBuyNowParams {
    address collection;
    address currency;
    address marketplace;
    uint256 tokenId;
    address vault;
    uint256 totalPrincipal;
    uint256 totalInterest;
    uint256 fee;
    uint256 incomeRatio;
    uint256 takeRate;
    address treasury;
    uint256 maxCreditLimit;
    uint256 totalOutstandingDebt;
    uint256 availableCreditLimit;
    uint256 totalDebt;
    uint256 outstandingPrincipal;
    uint256 outstandingInterest;
    uint256 fv;
    uint256 timestamp;
    uint40 term;
    uint40 epoch;
    uint40 nper;
    uint256 downpayment;
    uint256 borrowRate;
    uint256 availableLiquidity;
    uint256 totalSeniorBalance;
    uint256 totalJuniorBalance;
    uint256 totalPending;
    uint256 loanId;
    PMT pmt;
    AssetInfo assetInfo;
}

struct ExecuteLiquidateParams {
    address collection;
    address currency;
    address vault;
    uint256 loanId;
    uint256 repaymentId;
    uint256 remainingPrincipal;
    uint256 remainingInterest;
    uint256 remainingFee;
    uint256 totalDebt;
    uint256 collateralVaule;
    uint256 juniorTrancheAmount;
    address liquidator;
    uint256 liquidationBonus;
    uint256 writeDownAmount;
    uint256 incomeRatio;
    uint256 reducedAmount;
    uint256 writedownAmount;
}

library LibLoan {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using LibReserveConfiguration for ReserveConfigurationMap;

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
        uint256[] collateral;
    }

    struct ExecuteDebtParam {
        address collection;
        address currency;
        uint256 tokenId;
        address vault;
        uint256 principal;
        uint256 interest;
        uint40 term;
        uint40 epoch;
        uint256 apr;
        uint256 loanNumber;
        uint256 repaymentId;
    }

    event CollateralTransferred(
        address collection,
        address from,
        address to,
        uint256[] collaterals
    );

    /* ----------------------------- state mutations ---------------------------- */

    function releaseLien(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanId
    ) internal returns (uint256[] memory ret) {
        BorrowData storage borrowData = getBorrowData(
            _collection,
            _currency,
            _vault
        );

        Loan storage loan = borrowData.loans[_loanId];
        uint256[] storage collaterals = loan.collateral;
        ret = collaterals;
        for (uint256 i = 0; i < collaterals.length; i++) {
            delete LibAppStorage.ds().nftIndex[_collection][collaterals[i]];
        }
        delete borrowData.loans[_loanId];
        return ret;
    }

    function calculateInterest(
        address _collection,
        address _currency,
        uint256 _collateral,
        address _vault,
        uint256 _principal,
        uint40 _term,
        uint40 _epoch,
        uint256 _apr
    ) internal {
        ExecuteDebtParam memory param = composeExecuteDebtParam(
            _collection,
            _currency,
            _collateral,
            _vault,
            _principal,
            _term,
            _epoch,
            _apr
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
        loan.nper = uint40(
            (_term * SECOND_PER_DAY) / (_epoch * SECOND_PER_DAY)
        );
        loan.borrowAt = uint40(block.timestamp);
        uint256 periodsPerYear = SECONDS_PER_YEAR /
            (loan.epoch * SECOND_PER_DAY);
        uint256 effectiveInterestRate = (loan.apr * loan.nper) / periodsPerYear;
        loan.interest = loan.principal.rayMul(effectiveInterestRate);

        PMT memory pmt;
        pmt.principal = loan.principal / loan.nper;
        pmt.interest = loan.interest / loan.nper;
        pmt.pmt = pmt.principal + pmt.interest;
        loan.pmt = pmt;
    }

    function initDebt(
        BorrowState storage borrowState,
        BorrowData storage borrowData,
        ExecuteBuyNowParams memory param
    )
        internal
        returns (
            uint256 loanId,
            PMT memory pmt,
            uint256 totalInterest,
            uint256 protocolFee
        )
    {
        uint256 currentLoanNumber = borrowData.nextLoanNumber;
        Loan storage loan = borrowData.loans[currentLoanNumber];
        protocolFee = updateLoan(loan, param);

        pmt = previewPMT(
            loan.principal,
            loan.interest,
            loan.protocolFee,
            loan.nper
        );
        loan.pmt = pmt;

        loan.collateral.push(param.tokenId);
        LibAppStorage.ds().nftIndex[param.collection][
            param.tokenId
        ] = composeNFTInfo(param);
        loan.nextPaymentDue =
            loan.borrowAt +
            (loan.paidTimes + 1) *
            loan.epoch *
            uint40(SECOND_PER_DAY);

        updateBorrowData(
            borrowState,
            loan,
            borrowData,
            param.totalPrincipal,
            param.incomeRatio
        );

        return (currentLoanNumber, pmt, loan.interest, protocolFee);
    }

    function firstRepay(
        BorrowState storage borrowState,
        BorrowData storage debtData,
        uint256 _loanNumber,
        uint256 incomeRatio
    ) internal {
        Loan storage loan = debtData.loans[_loanNumber];
        loan.paidTimes += 1;
        insertRapayment(loan);
        updateDebtData(debtData, loan);
        uint256 numer = borrowState.totalDebt.rayMul(
            borrowState.avgBorrowRate
        ) - loan.pmt.principal.rayMul(loan.apr);
        uint256 denom = borrowState.totalDebt - loan.pmt.principal;
        borrowState.avgBorrowRate = numer.rayDiv(denom);
        // we suppose to call updateGlobalBorrowState here, but for gas optimization, the following
        // code inlined
        borrowState.totalDebt = borrowState.totalDebt - loan.pmt.principal;
        uint256 seniorInterest = loan.pmt.interest.percentMul(incomeRatio);
        if (borrowState.totalInterest < loan.pmt.interest) {
            borrowState.totalInterest = 0;
        } else {
            borrowState.totalInterest -= loan.pmt.interest;
        }
        if (borrowState.totalSeniorInterest < seniorInterest) {
            borrowState.totalSeniorInterest = 0;
        } else {
            borrowState.totalSeniorInterest -= seniorInterest;
        }
        uint256 juniorInterest = loan.pmt.interest - seniorInterest;

        if (borrowState.totalJuniorInterest < juniorInterest) {
            borrowState.totalJuniorInterest = 0;
        } else {
            borrowState.totalJuniorInterest -= juniorInterest;
        }
    }

    function closeDebt(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanNumber
    ) internal {
        ExecuteDebtParam memory param;
        param.collection = _collection;
        param.currency = _currency;
        param.vault = _vault;
        param.loanNumber = _loanNumber;
        (
            BorrowState storage borrowState,
            BorrowData storage debtData
        ) = getBorrowDataAndState(
                param.collection,
                param.currency,
                param.vault
            );
        Loan storage loan = debtData.loans[_loanNumber];
        updateDebtData(debtData, loan);
        updateGlobalBorrowState(borrowState, loan);
        clearLoan(debtData, borrowState, loan, param);
    }

    function repay(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanNumber
    ) internal returns (uint256, bool) {
        ExecuteDebtParam memory param;
        param.collection = _collection;
        param.currency = _currency;
        param.vault = _vault;
        param.loanNumber = _loanNumber;
        bool isFinal = false;

        (
            BorrowState storage borrowState,
            BorrowData storage debtData
        ) = getBorrowDataAndState(
                param.collection,
                param.currency,
                param.vault
            );
        Loan storage loan = debtData.loans[_loanNumber];
        loan.paidTimes += 1;
        param.repaymentId = loan.paidTimes - 1;

        updateDebtData(debtData, loan);
        updateGlobalBorrowState(borrowState, loan);
        isFinal = loan.paidTimes == loan.nper;
        if (isFinal) {
            debtData.paidLoanNumber += 1;
            clearLoan(debtData, borrowState, loan, param);
        } else {
            insertRapayment(loan);
        }

        return (param.repaymentId, isFinal);
    }

    function updateDebtData(BorrowData storage debtData, Loan storage loan)
        internal
    {
        debtData.totalPrincipal -= loan.pmt.principal;
        debtData.totalInterest -= loan.pmt.interest;
        debtData.totalFee -= loan.pmt.fee;
    }

    function updateGlobalBorrowState(
        BorrowState storage borrowState,
        Loan storage loan
    ) internal {
        if (borrowState.totalDebt <= loan.pmt.principal) {
            borrowState.avgBorrowRate = 0;
        } else {
            uint256 term1 = borrowState.totalDebt.rayMul(
                borrowState.avgBorrowRate
            );
            uint256 term2 = loan.pmt.principal.rayMul(loan.apr);
            // when the final open loan is being closed, integer arithmetic rounding issues can cause term1 to be <= term2
            // this occurs when principal is not factored by nper: e.g. principal of 100 and nper of 3
            // when taking the weighted rates, this can cause the computation to underflow by 1 wei
            if (term1 <= term2) {
                borrowState.avgBorrowRate = 0;
            } else {
                uint256 numer = term1 - term2;
                uint256 denom = borrowState.totalDebt - loan.pmt.principal;
                borrowState.avgBorrowRate = numer.rayDiv(denom);
            }
        }
        borrowState.totalDebt = borrowState.totalDebt - loan.pmt.principal;
        borrowState.totalInterest =
            borrowState.totalInterest -
            loan.pmt.interest;
        uint256 seniorInterest = loan.pmt.interest.percentMul(loan.incomeRatio);
        if (borrowState.totalSeniorInterest < seniorInterest) {
            borrowState.totalSeniorInterest = 0;
        } else {
            borrowState.totalSeniorInterest -= seniorInterest;
        }
        uint256 juniorInterest = loan.pmt.interest - seniorInterest;
        if (borrowState.totalJuniorInterest < juniorInterest) {
            borrowState.totalJuniorInterest = 0;
        } else {
            borrowState.totalJuniorInterest -= juniorInterest;
        }
    }

    function writedownSeniorInterest(
        BorrowState storage borrowState,
        uint256 interest
    ) internal {
        borrowState.totalSeniorInterest =
            borrowState.totalSeniorInterest -
            interest;
        borrowState.totalInterest = borrowState.totalInterest - interest;
    }

    function writedownJuniorInterest(
        BorrowState storage borrowState,
        uint256 interest
    ) internal {
        borrowState.totalJuniorInterest =
            borrowState.totalJuniorInterest -
            interest;
        borrowState.totalInterest = borrowState.totalInterest - interest;
    }

    function writedownSeniorPrincipal(
        BorrowState storage borrowState,
        uint256 principal
    ) internal {
        borrowState.totalDebt = borrowState.totalDebt - principal;
    }

    `function insertRapayment(Loan storage loan) internal {
        loan.totalPrincipalPaid = loan.totalPrincipalPaid + loan.pmt.principal;
        loan.totalInterestPaid = loan.totalInterestPaid + loan.pmt.interest;
        RepaymentData memory repayment;
        repayment.interest = loan.pmt.interest;
        repayment.principal = loan.pmt.principal;
        repayment.total = loan.pmt.principal + loan.pmt.interest;
        repayment.paidAt = uint40(block.timestamp);
        loan.repayments.push(repayment);
        // t, t+1, t+2
        loan.nextPaymentDue =
            loan.borrowAt +
            loan.paidTimes *
            loan.epoch *
            uint40(SECOND_PER_DAY);
    }

    function clearLoan(
        BorrowData storage debtData,
        BorrowState storage borrowState,
        Loan storage loan,
        ExecuteDebtParam memory param
    ) internal {
        uint256[] storage collaterals = loan.collateral;
        for (uint256 i = 0; i < collaterals.length; i++) {
            LibAppStorage
            .ds()
            .nftIndex[param.collection][collaterals[i]].isCollateral = false;
        }
        delete debtData.loans[param.loanNumber];
        borrowState.repayRecord[param.vault].repaidTimes =
            borrowState.repayRecord[param.vault].repaidTimes +
            1;
    }

    function getBorrowDataAndState(
        address collection,
        address currency,
        address vault
    )
        internal
        view
        returns (BorrowState storage borrowState, BorrowData storage borrowData)
    {
        borrowState = getBorrowState(collection, currency);
        borrowData = getBorrowData(collection, currency, vault);
        return (borrowState, borrowData);
    }

    function updateLoan(Loan storage loan, ExecuteBuyNowParams memory param)
        internal
        returns (uint256)
    {
        loan.principal = param.totalPrincipal;
        loan.term = param.term;
        loan.epoch = param.epoch;
        loan.apr = param.borrowRate;
        loan.nper = uint40(
            (param.term * SECOND_PER_DAY) / (param.epoch * SECOND_PER_DAY)
        );
        loan.borrowAt = uint40(block.timestamp);
        loan.interest = previewInterest(
            loan.principal,
            loan.apr,
            loan.epoch,
            loan.nper
        );
        loan.protocolFee = loan.principal.percentMul(param.takeRate);
        loan.incomeRatio = param.incomeRatio;
        return loan.protocolFee;
    }

    function previewInterest(
        uint256 principal,
        uint256 apr,
        uint256 epoch,
        uint256 nper
    ) internal view returns (uint256) {
        uint256 periodsPerYear = SECONDS_PER_YEAR / (epoch * SECOND_PER_DAY);
        uint256 effectiveInterestRate = (apr * nper) / periodsPerYear;
        return principal.rayMul(effectiveInterestRate);
    }

    function previewPMT(
        uint256 principal,
        uint256 interest,
        uint256 fee,
        uint256 nper
    ) internal pure returns (PMT memory) {
        PMT memory pmt;
        pmt.principal = principal / nper;
        pmt.interest = interest / nper;
        pmt.fee = fee / nper;
        pmt.pmt = pmt.principal + pmt.interest + pmt.fee;
        return pmt;
    }

    function composeExecuteDebtParam(
        address _collection,
        address _currency,
        uint256 _collateral,
        address _vault,
        uint256 _principal,
        uint40 _term,
        uint40 _epoch,
        uint256 _apr
    ) internal pure returns (ExecuteDebtParam memory param) {
        param.collection = _collection;
        param.currency = _currency;
        param.tokenId = _collateral;
        param.vault = _vault;
        param.principal = _principal;
        param.term = _term;
        param.epoch = _epoch;
        param.apr = _apr;
        return param;
    }

    function composeNFTInfo(ExecuteBuyNowParams memory param)
        internal
        pure
        returns (NFTInfo memory nftInfo)
    {
        nftInfo.collection = param.collection;
        nftInfo.tokenId = param.tokenId;
        nftInfo.currency = param.currency;
        nftInfo.price = param.totalPrincipal;
        nftInfo.isCollateral = true;
        return nftInfo;
    }

    function updateBorrowData(
        BorrowState storage borrowState,
        Loan storage loan,
        BorrowData storage borrowData,
        uint256 principal,
        uint256 incomeRatio
    ) internal {
        borrowData.nextLoanNumber++;
        borrowData.mapSize++;
        borrowData.totalPrincipal += principal;
        borrowData.totalInterest += loan.interest;
        borrowData.totalFee += loan.protocolFee;
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

        uint256 seniorInterest = loan.interest.percentMul(incomeRatio);
        borrowState.totalSeniorInterest =
            borrowState.totalSeniorInterest +
            seniorInterest;
        borrowState.totalJuniorInterest =
            borrowState.totalJuniorInterest +
            loan.interest -
            seniorInterest;
    }

    function distributeInterest(
        ReserveData memory reserveData,
        uint256 interest,
        address sender,
        uint256 incomeRatio
    ) internal {
        uint256 seniorInterest = interest.percentMul(incomeRatio);

        IERC20(reserveData.currency).safeTransferFrom(
            sender,
            reserveData.seniorDepositTokenAddress,
            seniorInterest
        );

        IERC20(reserveData.currency).safeTransferFrom(
            sender,
            reserveData.juniorDepositTokenAddress,
            interest - seniorInterest
        );
    }

    function tryRepay(
        uint256 remainingAmount,
        uint256 amount,
        address currency,
        address depositTokenAddr
    ) internal returns (uint256 reducedAmount, uint256 writedownAmount) {
        if (remainingAmount == 0) {
            return (0, amount);
        }
        if (remainingAmount > amount) {
            IERC20(currency).safeTransfer(depositTokenAddr, amount);
            reducedAmount = amount;
        } else {
            IERC20(currency).safeTransfer(depositTokenAddr, remainingAmount);
            reducedAmount = remainingAmount;
            writedownAmount = amount - remainingAmount;
        }
        return (reducedAmount, writedownAmount);
    }

    function getInterest(
        ReserveData memory reserveData,
        uint256 interest,
        uint256 incomeRatio
    ) internal view returns (uint256, uint256) {
        uint256 seniorInterest = interest.percentMul(incomeRatio);
        return (seniorInterest, interest - seniorInterest);
    }

    function transferCollateral(
        uint256[] memory collaterals,
        address collection,
        address liquidator,
        address vault
    ) internal {
        for (uint256 i = 0; i < collaterals.length; i++) {
            bytes4 selector = IERC721(collection).transferFrom.selector;
            bytes memory data = abi.encodePacked(
                selector,
                abi.encode(vault, liquidator, collaterals[i])
            );
            IVault(vault).execute(data, collection, 0);
        }
        emit CollateralTransferred(collection, vault, liquidator, collaterals);
    }

    function distributeProtocolFee(
        ReserveData memory reserveData,
        uint256 fee,
        address sender,
        address treasury
    ) internal {
        IERC20(reserveData.currency).safeTransferFrom(sender, treasury, fee);
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
        BorrowData storage borrowData,
        address _currency,
        uint256 _loanId
    ) internal view returns (LoanDetail memory) {
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
        loanDetail.collateral = loan.collateral;
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
    ) internal view returns (uint40, uint40) {
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
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        AppStorage storage s = LibAppStorage.ds();
        Loan storage loan = s._borrowData[_collection][_currency][_vault].loans[
            _loan
        ];
        return (loan.pmt.principal, loan.pmt.interest, loan.pmt.fee);
    }

    function getRemainingDebt(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loanId
    )
        internal
        view
        returns (
            uint256 remaningPrincipal,
            uint256 remaningInterest,
            uint256 remaningFee,
            uint256 incomeRatio
        )
    {
        AppStorage storage s = LibAppStorage.ds();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        return (
            borrowData.totalPrincipal,
            borrowData.totalInterest,
            borrowData.totalFee,
            borrowData.loans[_loanId].incomeRatio
        );
    }

    function getIncomeRatio(
        address _collection,
        address _currency,
        address _vault,
        uint256 _loan
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.ds();
        Loan storage loan = s._borrowData[_collection][_currency][_vault].loans[
            _loan
        ];
        return loan.incomeRatio;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IRepaymentFacet} from "../interfaces/IRepaymentFacet.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibAppStorage, AppStorage, Storage, BorrowData, BorrowState, Loan, ReserveConfigurationMap, ReserveData, PMT} from "../libraries/LibAppStorage.sol";
import {ILoanFacet, ExecuteRepayParams, PreviewBuyNowParams} from "../interfaces/ILoanFacet.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibLoan} from "../libraries/LibLoan.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {LibPayments} from "../../shared/libraries/LibPayments.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";

contract RepaymentFacet is Storage, ReentrancyGuard, IRepaymentFacet {
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    event Repayment(
        address indexed _user,
        address indexed _vault,
        address indexed _collection,
        address _currency,
        uint256 _loanId,
        uint256 _repaymentId,
        uint256 _amount,
        bool isFinal
    );

    function repay(
        address _collection,
        uint256 _loan,
        address payable _vault
    ) external whenNotPaused nonReentrant {
        ExecuteRepayParams memory params;
        ReserveData memory reserveData = LibLiquidity.getReserveData(
            _collection
        );

        // 0. check if the user owns the vault
        if (LibVault.getVaultAddress(_msgSender()) != _vault) {
            revert("Unauthorised");
        }

        params.vault = _vault;

        // 1. check draw down to get principal and interest
        (params.principal, params.interest, params.fee) = LibLoan.getPMT(
            _collection,
            reserveData.currency,
            _vault,
            _loan
        );
        if (params.principal + params.interest == 0) {
            revert InvalidDebt();
        }

        params.total = params.principal + params.interest;
        params.incomeRatio = LibLoan.getIncomeRatio(
            _collection,
            reserveData.currency,
            _vault,
            _loan
        );
        (params.takeRate, params.treasury) = LibLiquidity
            .getTakeRateAndTreasuryAddr();

        // 2. update repay data
        (uint256 repaymentId, bool isFinal) = LibLoan.repay(
            _collection,
            reserveData.currency,
            _vault,
            _loan
        );

        uint256 vaultWETHBalance = IERC20(reserveData.currency).balanceOf(
            params.vault
        );
        if (
            params.interest + params.fee + params.principal > vaultWETHBalance
        ) {
            LibPayments.wrapAndUnwrapETH(
                params.vault,
                0,
                params.interest +
                    params.fee +
                    params.principal -
                    vaultWETHBalance
            );
        }

        // 3. distribute interest
        LibLoan.distributeInterest(
            reserveData,
            params.interest,
            params.vault,
            params.incomeRatio
        );

        // 4. distribute fee
        LibLoan.distributeProtocolFee(
            reserveData,
            params.fee,
            params.vault,
            params.treasury
        );

        IERC20(reserveData.currency).safeTransferFrom(
            params.vault,
            reserveData.seniorDepositTokenAddress,
            params.principal
        );

        emit Repayment(
            _msgSender(),
            _vault,
            _collection,
            reserveData.currency,
            _loan,
            repaymentId,
            params.total,
            isFinal
        );
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidDebt();

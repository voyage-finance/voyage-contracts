// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {IDataProvider, CreditLineData, PoolData, UserPoolData, PoolConfiguration} from "../interfaces/IDataProvider.sol";
import {AppStorage, ReserveData, BorrowData, ReserveConfigurationMap, Tranche, LoanList, RepaymentData, LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibLoan} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {IUnbondingToken} from "../tokenization/SeniorDepositToken.sol";

contract DataProviderFacet is IDataProvider {
    using WadRayMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    function getPoolConfiguration(address _collection)
        external
        view
        returns (PoolConfiguration memory)
    {
        PoolConfiguration memory poolConfiguration;
        ReserveConfigurationMap memory config = LibReserveConfiguration
            .getConfiguration(_collection);
        poolConfiguration.liquidationBonus = config.getLiquidationBonus();
        poolConfiguration.incomeRatio = config.getIncomeRatio();

        return poolConfiguration;
    }

    function getPoolData(address _collection)
        external
        view
        returns (PoolData memory)
    {
        LibLiquidity.DepositAndDebt memory depositAndDebt = LibLiquidity
            .getDepositAndDebt(_collection);
        IERC20Metadata token = IERC20Metadata(depositAndDebt.currency);

        PoolData memory poolData;
        poolData.currency = depositAndDebt.currency;
        poolData.juniorLiquidity = depositAndDebt.juniorDepositAmount;
        poolData.seniorLiquidity = depositAndDebt.seniorDepositAmount;
        poolData.totalLiquidity =
            depositAndDebt.seniorDepositAmount +
            depositAndDebt.juniorDepositAmount;
        poolData.totalDebt = depositAndDebt.totalDebt;
        if (depositAndDebt.seniorDepositAmount == 0) {
            poolData.trancheRatio = 0;
        } else {
            poolData.trancheRatio = depositAndDebt.juniorDepositAmount.rayDiv(
                depositAndDebt.seniorDepositAmount
            );
        }

        poolData.decimals = token.decimals();
        poolData.utilizationRate = LibLiquidity.utilizationRate(_collection);
        poolData.symbol = token.symbol();
        (poolData.isActive, , ) = LibReserveConfiguration
            .getConfiguration(_collection)
            .getFlags();

        return poolData;
    }

    function getDepositTokens(address _collection)
        external
        view
        returns (address senior, address junior)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);
        senior = reserve.seniorDepositTokenAddress;
        junior = reserve.juniorDepositTokenAddress;
    }

    function getVault(address _user) external view returns (address) {
        return LibVault.getVaultAddress(_user);
    }

    function getCollections() external view returns (address[] memory) {
        return LibLiquidity.getReserveList();
    }

    function getUserPoolData(address _collection, address _user)
        external
        view
        returns (UserPoolData memory)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);
        UserPoolData memory userPoolData;
        IERC20Metadata token = IERC20Metadata(reserve.currency);

        uint256 seniorTrancheWithdrawable = LibLiquidity.balance(
            _collection,
            _user,
            Tranche.SENIOR
        );
        uint256 seniorTrancheUnbonding = LibLiquidity.unbonding(
            _collection,
            _user
        );
        uint256 seniorTrancheTotalBalance = seniorTrancheWithdrawable +
            seniorTrancheUnbonding;
        userPoolData.juniorTrancheBalance = LibLiquidity.balance(
            _collection,
            _user,
            Tranche.JUNIOR
        );
        userPoolData.seniorTrancheBalance = seniorTrancheTotalBalance;
        userPoolData
            .withdrawableSeniorTrancheBalance = seniorTrancheWithdrawable;
        userPoolData.decimals = token.decimals();
        return userPoolData;
    }

    function getCreditLineData(address _vault, address _collection)
        external
        view
        returns (CreditLineData memory)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);
        CreditLineData memory creditLineData;
        uint256 principal;
        uint256 interest;
        LoanList memory loanList;
        (loanList.head, loanList.tail) = LibLoan.getLoanList(
            _collection,
            reserve.currency,
            _vault
        );
        (principal, interest) = LibVault.getVaultDebt(
            _collection,
            reserve.currency,
            _vault
        );
        creditLineData.loanList = loanList;
        creditLineData.totalDebt = principal + interest;
        creditLineData.ltv = creditLineData.totalDebt == 0
            ? 1
            : (creditLineData.gav).rayDiv(creditLineData.totalDebt);
        return creditLineData;
    }

    function getLoanDetail(
        address _vault,
        address _collection,
        uint256 _loanId
    ) external view returns (LibLoan.LoanDetail memory) {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);
        BorrowData storage borrowData = LibLoan.getBorrowData(
            _collection,
            reserve.currency,
            _vault
        );
        return LibLoan.getLoanDetail(borrowData, reserve.currency, _loanId);
    }

    function getRepayment(
        address _valut,
        address _collection,
        uint256 _loanId
    ) external view returns (RepaymentData[] memory) {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);
        return
            LibLoan.getRepayment(
                _collection,
                _valut,
                reserve.currency,
                _loanId
            );
    }

    function pendingSeniorWithdrawals(address _user, address _collection)
        external
        view
        returns (uint256)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);

        return
            IUnbondingToken(reserve.seniorDepositTokenAddress).unbonding(_user);
    }

    function getProtocolFeeParam() external view returns (address, uint256) {
        AppStorage storage s = LibAppStorage.ds();
        return (s.protocolFee.treasuryAddress, s.protocolFee.takeRate);
    }
}

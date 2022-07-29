// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {AppStorage, ReserveData, ReserveConfigurationMap, Tranche, VaultConfig, LoanList, RepaymentData} from "../libraries/LibAppStorage.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibLoan} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import "hardhat/console.sol";

struct CreditLineData {
    uint256 totalDebt;
    LoanList loanList;
    uint256 totalMargin;
    uint256 withdrawableSecurityDeposit;
    uint256 creditLimit;
    uint256 spendableBalance;
    uint256 gav;
    uint256 ltv;
    uint256 healthFactor;
}

contract DataProviderFacet {
    using WadRayMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    AppStorage internal s;

    struct PoolData {
        address currency;
        uint256 totalLiquidity;
        uint256 juniorLiquidity;
        uint256 seniorLiquidity;
        uint256 juniorLiquidityRate;
        uint256 seniorLiquidityRate;
        uint256 totalDebt;
        uint256 utilizationRate;
        uint256 trancheRatio;
        uint256 decimals;
        string symbol;
        bool isActive;
    }

    struct UserPoolData {
        uint256 juniorTrancheBalance;
        uint256 withdrawableJuniorTrancheBalance;
        uint256 seniorTrancheBalance;
        uint256 withdrawableSeniorTrancheBalance;
        uint256 decimals;
    }

    struct PoolConfiguration {
        uint256 liquidationBonus;
        uint256 marginRequirement;
        uint256 minMargin;
        uint256 maxMargin;
        uint256 loanInterval;
        uint256 loanTenure;
        uint256 incomeRatio;
        bool isInitialized;
        bool isActive;
    }

    struct FungibleTokenData {
        string symbol;
        address tokenAddress;
    }

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
        (
            poolConfiguration.marginRequirement,
            poolConfiguration.minMargin,
            poolConfiguration.maxMargin
        ) = config.getMarginParams();
        (poolConfiguration.isActive, , ) = config.getFlags();

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
        public
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

    function getPoolTokens()
        external
        view
        returns (FungibleTokenData[] memory tokens)
    {
        address[] memory collections = LibLiquidity.getReserveList();

        FungibleTokenData[] memory currencies = new FungibleTokenData[](
            collections.length
        );

        for (uint256 i = 0; i < collections.length; ) {
            ReserveData memory reserve = LibLiquidity.getReserveData(
                collections[i]
            );
            currencies[i] = FungibleTokenData({
                symbol: IERC20Metadata(reserve.currency).symbol(),
                tokenAddress: reserve.currency
            });
            unchecked {
                ++i;
            }
        }

        return currencies;
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
            _user,
            Tranche.SENIOR
        );
        uint256 seniorTrancheTotalBalance = seniorTrancheWithdrawable +
            seniorTrancheUnbonding;
        uint256 juniorTrancheWithdrawable = LibLiquidity.balance(
            _collection,
            _user,
            Tranche.JUNIOR
        );
        uint256 juniorTrancheUnbonding = LibLiquidity.unbonding(
            _collection,
            _user,
            Tranche.JUNIOR
        );
        uint256 juniorTrancheTotalBalance = juniorTrancheWithdrawable +
            juniorTrancheUnbonding;

        userPoolData.juniorTrancheBalance = juniorTrancheTotalBalance;
        userPoolData
            .withdrawableJuniorTrancheBalance = juniorTrancheWithdrawable;
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
        creditLineData.totalMargin = LibVault.getMargin(
            _vault,
            reserve.currency
        );
        creditLineData.withdrawableSecurityDeposit = LibVault
            .getTotalWithdrawableMargin(_vault, reserve.currency);
        creditLineData.creditLimit = LibVault.getCreditLimit(
            _vault,
            _collection
        );
        creditLineData.spendableBalance = LibVault.getAvailableCredit(
            _vault,
            _collection
        );
        creditLineData.ltv = creditLineData.totalDebt == 0
            ? 1
            : (creditLineData.gav + creditLineData.totalMargin).rayDiv(
                creditLineData.totalDebt
            );
        return creditLineData;
    }

    function getLoanDetail(
        address _vault,
        address _collection,
        uint256 _loanId
    ) external view returns (LibLoan.LoanDetail memory) {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);
        return
            LibLoan.getLoanDetail(
                _collection,
                reserve.currency,
                _vault,
                _loanId
            );
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
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);

        (uint256[] memory times, uint256[] memory amounts) = IVToken(
            reserve.seniorDepositTokenAddress
        ).unbonding(_user);

        return (times, amounts);
    }

    function pendingJuniorWithdrawals(address _user, address _collection)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_collection);

        (uint256[] memory times, uint256[] memory amounts) = IVToken(
            reserve.juniorDepositTokenAddress
        ).unbonding(_user);

        return (times, amounts);
    }

    function getMarginConfiguration(address _collection)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        uint256 decimals = conf.getDecimals();
        uint256 assetUnit = 10**decimals;
        (
            uint256 min,
            uint256 max,
            uint256 marginRequirement
        ) = LibReserveConfiguration
                .getConfiguration(_collection)
                .getMarginParams();
        return (min * assetUnit, max * assetUnit, marginRequirement);
    }
}

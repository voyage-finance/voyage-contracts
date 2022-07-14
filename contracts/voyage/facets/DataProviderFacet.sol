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
        uint256 apr;
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

    function getPoolConfiguration(address _reserve)
        external
        view
        returns (PoolConfiguration memory)
    {
        PoolConfiguration memory poolConfiguration;
        ReserveConfigurationMap memory config = LibReserveConfiguration
            .getConfiguration(_reserve);
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

    function getPoolData(address _asset)
        external
        view
        returns (PoolData memory)
    {
        LibLiquidity.DepositAndDebt memory depositAndDebt = LibLiquidity
            .getDepositAndDebt(_asset);
        IERC20Metadata token = IERC20Metadata(_asset);

        PoolData memory poolData;
        poolData.juniorLiquidity = depositAndDebt.juniorDepositAmount;
        poolData.seniorLiquidity = depositAndDebt.seniorDepositAmount;
        poolData.totalLiquidity =
            depositAndDebt.seniorDepositAmount +
            depositAndDebt.juniorDepositAmount;
        poolData.juniorLiquidityRate = LibLiquidity.getLiquidityRate(
            _asset,
            Tranche.JUNIOR
        );
        poolData.seniorLiquidityRate = LibLiquidity.getLiquidityRate(
            _asset,
            Tranche.SENIOR
        );
        poolData.totalDebt = depositAndDebt.totalDebt;
        if (depositAndDebt.seniorDepositAmount == 0) {
            poolData.trancheRatio = 0;
        } else {
            poolData.trancheRatio = depositAndDebt.juniorDepositAmount.rayDiv(
                depositAndDebt.seniorDepositAmount
            );
        }

        poolData.decimals = token.decimals();
        poolData.utilizationRate = LibLiquidity.utilizationRate(_asset);
        poolData.symbol = token.symbol();
        (poolData.isActive, , ) = LibReserveConfiguration
            .getConfiguration(_asset)
            .getFlags();

        return poolData;
    }

    function getDepositTokens(address _asset)
        public
        view
        returns (address senior, address junior)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_asset);
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
        address[] memory reserveList = LibLiquidity.getReserveList();

        FungibleTokenData[] memory reserves = new FungibleTokenData[](
            reserveList.length
        );

        for (uint256 i = 0; i < reserveList.length; ) {
            address reserveAddress = reserveList[i];
            reserves[i] = FungibleTokenData({
                symbol: IERC20Metadata(reserveAddress).symbol(),
                tokenAddress: reserveAddress
            });
            unchecked {
                ++i;
            }
        }

        return reserves;
    }

    function getUserPoolData(address _reserve, address _user)
        external
        view
        returns (UserPoolData memory)
    {
        UserPoolData memory userPoolData;
        IERC20Metadata token = IERC20Metadata(_reserve);

        uint256 seniorTrancheWithdrawable = LibLiquidity.balance(
            _reserve,
            _user,
            Tranche.SENIOR
        );
        uint256 seniorTrancheUnbonding = LibLiquidity.unbonding(
            _reserve,
            _user,
            Tranche.SENIOR
        );
        uint256 seniorTrancheTotalBalance = seniorTrancheWithdrawable +
            seniorTrancheUnbonding;
        uint256 juniorTrancheWithdrawable = LibLiquidity.balance(
            _reserve,
            _user,
            Tranche.JUNIOR
        );
        uint256 juniorTrancheUnbonding = LibLiquidity.unbonding(
            _reserve,
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

    function getCreditLineData(address _vault, address _reserve)
        external
        view
        returns (CreditLineData memory)
    {
        CreditLineData memory creditLineData;
        uint256 principal;
        uint256 interest;
        LoanList memory loanList;
        (loanList.head, loanList.tail) = LibLoan.getLoanList(_reserve, _vault);
        (principal, interest) = LibVault.getVaultDebt(_reserve, _vault);
        creditLineData.loanList = loanList;
        creditLineData.totalDebt = principal + interest;
        creditLineData.totalMargin = LibVault.getMargin(_vault, _reserve);
        creditLineData.withdrawableSecurityDeposit = LibVault
            .getTotalWithdrawableMargin(_vault, _reserve);
        creditLineData.creditLimit = LibVault.getCreditLimit(_vault, _reserve);
        creditLineData.spendableBalance = LibVault.getAvailableCredit(
            _vault,
            _reserve
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
        address _reserve,
        uint256 _loanId
    ) external view returns (LibLoan.LoanDetail memory) {
        return LibLoan.getLoanDetail(_reserve, _vault, _loanId);
    }

    function getRepayment(
        address _valut,
        address _reserve,
        uint256 _loanId
    ) external view returns (RepaymentData[] memory) {
        return LibLoan.getRepayment(_valut, _reserve, _loanId);
    }

    function pendingSeniorWithdrawals(address _user, address _reserve)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_reserve);

        (uint256[] memory times, uint256[] memory amounts) = IVToken(
            reserve.seniorDepositTokenAddress
        ).unbonding(_user);

        return (times, amounts);
    }

    function pendingJuniorWithdrawals(address _user, address _reserve)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        ReserveData memory reserve = LibLiquidity.getReserveData(_reserve);

        (uint256[] memory times, uint256[] memory amounts) = IVToken(
            reserve.juniorDepositTokenAddress
        ).unbonding(_user);

        return (times, amounts);
    }

    function getVaultConfig(address _reserve)
        external
        view
        returns (VaultConfig memory)
    {
        return LibVault.getVaultConfig(_reserve);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {AppStorage, ReserveData, Tranche, VaultConfig, VaultData, LoanList, RepaymentData} from "../libraries/LibAppStorage.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {LibLoan} from "../libraries/LibLoan.sol";
import {LibVault} from "../libraries/LibVault.sol";

contract DataProviderFacet {
    using WadRayMath for uint256;

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
        uint256 marginRequirement;
        uint256 minMargin;
        uint256 maxMargin;
        uint256 loanTenure;
        uint256 optimalTrancheRatio;
        uint256 optimalIncomeRatio;
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
        ReserveData memory reserve = LibLiquidity.getReserveData(_reserve);
        VaultConfig memory vc = LibVault.getVaultConfig(_reserve);
        poolConfiguration.marginRequirement = vc.marginRequirement;
        poolConfiguration.minMargin = vc.minMargin;
        poolConfiguration.maxMargin = vc.maxMargin;
        poolConfiguration.optimalIncomeRatio = reserve.optimalIncomeRatio;
        poolConfiguration.optimalTrancheRatio = reserve.optimalTrancheRatio;
        (bool isActive, , ) = LibLiquidity.getFlags(_reserve);
        poolConfiguration.isActive = isActive;

        return poolConfiguration;
    }

    function getPoolData(address underlyingAsset)
        external
        view
        returns (PoolData memory)
    {
        LibLiquidity.DepositAndDebt memory depositAndDebt = LibLiquidity
            .getDepositAndDebt(underlyingAsset);
        IERC20Metadata token = IERC20Metadata(underlyingAsset);

        PoolData memory poolData;
        poolData.juniorLiquidity = depositAndDebt.juniorDepositAmount;
        poolData.seniorLiquidity = depositAndDebt.seniorDepositAmount;
        poolData.totalLiquidity =
            depositAndDebt.seniorDepositAmount +
            depositAndDebt.juniorDepositAmount;
        poolData.juniorLiquidityRate = LibLiquidity.getLiquidityRate(
            underlyingAsset,
            Tranche.JUNIOR
        );
        poolData.seniorLiquidityRate = LibLiquidity.getLiquidityRate(
            underlyingAsset,
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
        poolData.utilizationRate = LibLiquidity.utilizationRate(
            underlyingAsset
        );
        poolData.symbol = token.symbol();
        (bool isActive, , ) = LibLiquidity.getFlags(underlyingAsset);
        poolData.isActive = isActive;

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

    function getVaultData(address _vault, address _reserve)
        external
        view
        returns (VaultData memory)
    {
        VaultData memory vaultData;
        uint256 principal;
        uint256 interest;
        LoanList memory loanList;
        (loanList.head, loanList.tail) = LibLoan.getLoanList(_reserve, _vault);
        (principal, interest) = LibVault.getVaultDebt(_reserve, _vault);
        vaultData.loanList = loanList;
        ReserveData storage reserveData = LibLiquidity.getReserveData(_reserve);
        vaultData.totalDebt = principal + interest;
        vaultData.totalMargin = LibVault.getMargin(_vault, _reserve);
        vaultData.withdrawableSecurityDeposit = LibVault
            .getTotalWithdrawableMargin(_vault, _reserve);
        vaultData.creditLimit = LibVault.getCreditLimit(_vault, _reserve);
        vaultData.spendableBalance = LibVault.getAvailableCredit(
            _vault,
            _reserve
        );
        vaultData.ltv = vaultData.totalDebt == 0
            ? 1
            : (vaultData.gav + vaultData.totalMargin).rayDiv(
                vaultData.totalDebt
            );

        return vaultData;
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

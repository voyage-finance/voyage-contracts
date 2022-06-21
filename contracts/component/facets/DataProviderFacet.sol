// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IAddressResolver} from "../../interfaces/IAddressResolver.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IVToken} from "../../interfaces/IVToken.sol";
import {AppStorage, ADDRESS_RESOLVER, ReserveData, Tranche, VaultConfig, VaultData, DrawDownList} from "../../libraries/LibAppStorage.sol";
import {LibLiquidity} from "../../libraries/LibLiquidity.sol";
import {LibLoan} from "../../libraries/LibLoan.sol";
import {LibVault} from "../../libraries/LibVault.sol";

contract DataProviderFacet {
    using SafeMath for uint256;
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
        uint256 securityRequirement;
        uint256 minSecurity;
        uint256 maxSecurity;
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
        address healthStrategyAddr = reserve.healthStrategyAddress;
        require(healthStrategyAddr != address(0), "invalid health strategy");
        VaultConfig memory vc = LibVault.getVaultConfig(_reserve);
        poolConfiguration.securityRequirement = vc.securityDepositRequirement;
        poolConfiguration.minSecurity = vc.minSecurityDeposit;
        poolConfiguration.maxSecurity = vc.maxSecurityDeposit;
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
        poolData.totalLiquidity = depositAndDebt.seniorDepositAmount.add(
            depositAndDebt.juniorDepositAmount
        );
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

    function getUserVault(address _user) external view returns (address) {
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

        for (uint256 i = 0; i < reserveList.length; i++) {
            address reserveAddress = reserveList[i];
            reserves[i] = FungibleTokenData({
                symbol: IERC20Metadata(reserveAddress).symbol(),
                tokenAddress: reserveAddress
            });
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
        uint256 seniorTrancheTotalBalance = seniorTrancheWithdrawable.add(
            seniorTrancheUnbonding
        );
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
        uint256 juniorTrancheTotalBalance = juniorTrancheWithdrawable.add(
            juniorTrancheUnbonding
        );

        userPoolData.juniorTrancheBalance = juniorTrancheTotalBalance;
        userPoolData
            .withdrawableJuniorTrancheBalance = juniorTrancheWithdrawable;
        userPoolData.seniorTrancheBalance = seniorTrancheTotalBalance;
        userPoolData
            .withdrawableSeniorTrancheBalance = seniorTrancheWithdrawable;
        userPoolData.decimals = token.decimals();

        return userPoolData;
    }

    function getVaultData(
        address _user,
        address _reserve,
        address _sponsor
    ) external view returns (VaultData memory) {
        VaultData memory vaultData;
        address vault = LibVault.getVaultAddress(_user);
        uint256 principal;
        uint256 interest;
        DrawDownList memory drawDownList;
        (drawDownList.head, drawDownList.tail) = LibLoan.getDrawDownList(
            _reserve,
            vault
        );
        (principal, interest) = LibVault.getVaultDebt(_reserve, vault);
        vaultData.drawDownList = drawDownList;
        vaultData.borrowRate = 0;
        vaultData.totalDebt = principal.add(interest);
        vaultData.totalSecurityDeposit = LibVault.getSecurityDeposit(
            _user,
            _reserve
        );
        vaultData.withdrawableSecurityDeposit = LibVault.getWithdrawableDeposit(
            _user,
            _reserve,
            _sponsor
        );
        vaultData.totalSecurityDeposit = LibVault.getSecurityDeposit(
            _user,
            _reserve
        );
        vaultData.creditLimit = LibVault.getCreditLimit(_user, _reserve);
        vaultData.spendableBalance = LibVault.getAvailableCredit(
            _user,
            _reserve
        );
        vaultData.ltv = vaultData
            .gav
            .add(vaultData.totalSecurityDeposit)
            .rayDiv(vaultData.totalDebt);

        return vaultData;
    }

    function getDrawDownDetail(
        address _user,
        address _reserve,
        uint256 _drawDownId
    ) external view returns (LibLoan.DebtDetail memory) {
        address vault = LibVault.getVaultAddress(_user);
        return LibLoan.getDrawDownDetail(_reserve, vault, _drawDownId);
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

    function addressResolver() internal view returns (IAddressResolver) {
        return IAddressResolver(s._addresses[ADDRESS_RESOLVER]);
    }
}

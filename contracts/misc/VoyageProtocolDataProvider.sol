// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/IReserveManager.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../libraries/types/DataTypes.sol';
import '../libraries/logic/ReserveLogic.sol';
import '../libraries/math/WadRayMath.sol';
import '../interfaces/IVaultManager.sol';
import '../interfaces/IHealthStrategy.sol';
import '../interfaces/IVaultManagerProxy.sol';
import '../interfaces/ILiquidityManagerProxy.sol';
import '../interfaces/IStableDebtToken.sol';
import '../component/liquidity/LiquidityManager.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import 'hardhat/console.sol';

contract VoyageProtocolDataProvider {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    IAddressResolver public addressResolver;

    constructor(IAddressResolver _addressResolver) {
        addressResolver = _addressResolver;
    }

    function getPoolConfiguration(address _reserve)
        external
        view
        returns (DataTypes.PoolConfiguration memory)
    {
        DataTypes.PoolConfiguration memory poolConfiguration;
        IVaultManager vm = IVaultManager(
            addressResolver.getVaultManagerProxy()
        );
        IReserveManager rm = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(_reserve);
        address healthStrategyAddr = reserve.healthStrategyAddress;
        require(healthStrategyAddr != address(0), 'invalid health strategy');
        IHealthStrategy hs = IHealthStrategy(healthStrategyAddr);
        DataTypes.VaultConfig memory vc = vm.getVaultConfig(_reserve);
        poolConfiguration.securityRequirement = vc.securityDepositRequirement;
        poolConfiguration.minSecurity = vc.minSecurityDeposit;
        poolConfiguration.maxSecurity = vc.maxSecurityDeposit;
        poolConfiguration.loanTenure = hs.getLoanTenure();
        poolConfiguration.optimalIncomeRatio = reserve.optimalIncomeRatio;
        poolConfiguration.optimalTrancheRatio = reserve.optimalTrancheRatio;
        return poolConfiguration;
    }

    function getPoolData(address underlyingAsset)
        external
        view
        returns (DataTypes.PoolData memory)
    {
        IReserveManager rm = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(
            underlyingAsset
        );
        ILiquidityManagerProxy lmp = ILiquidityManagerProxy(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.DepositAndDebt memory depositAndDebt = lmp
            .getLiquidityAndDebt(underlyingAsset);
        IERC20Metadata token = IERC20Metadata(underlyingAsset);

        DataTypes.PoolData memory poolData;
        poolData.juniorLiquidity = depositAndDebt.juniorDepositAmount;
        poolData.seniorLiquidity = depositAndDebt.seniorDepositAmount;
        poolData.totalLiquidity = depositAndDebt.seniorDepositAmount.add(
            depositAndDebt.juniorDepositAmount
        );
        poolData.juniorLiquidityRate = lmp.getLiquidityRate(
            underlyingAsset,
            ReserveLogic.Tranche.JUNIOR
        );
        poolData.seniorLiquidityRate = lmp.getLiquidityRate(
            underlyingAsset,
            ReserveLogic.Tranche.SENIOR
        );
        poolData.totalDebt = depositAndDebt.totalDebt;
        poolData.borrowRate = reserve.currentBorrowRate;
        poolData.trancheRatio = depositAndDebt.juniorDepositAmount.rayDiv(
            depositAndDebt.seniorDepositAmount
        );
        poolData.decimals = token.decimals();

        return poolData;
    }

    function getAllVaults() external view returns (address[] memory) {
        IVaultManagerProxy vmp = IVaultManagerProxy(
            addressResolver.getVaultManagerProxy()
        );
        return vmp.getAllVaults();
    }

    function getUserVault(address _user) external view returns (address) {
        IVaultManagerProxy vmp = IVaultManagerProxy(
            addressResolver.getVaultManagerProxy()
        );
        return vmp.getVault(_user);
    }

    function getPoolTokens()
        external
        view
        returns (DataTypes.FungibleTokenData[] memory tokens)
    {
        address[] memory reserveList = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        ).getReserveList();

        DataTypes.FungibleTokenData[]
            memory reserves = new DataTypes.FungibleTokenData[](
                reserveList.length
            );

        for (uint256 i = 0; i < reserveList.length; i++) {
            address reserveAddress = reserveList[i];
            reserves[i] = DataTypes.FungibleTokenData({
                symbol: IERC20Metadata(reserveAddress).symbol(),
                tokenAddress: reserveAddress
            });
        }

        return reserves;
    }

    function getUserPoolData(address _reserve, address _user)
        external
        view
        returns (DataTypes.UserPoolData memory)
    {
        ILiquidityManagerProxy lmp = ILiquidityManagerProxy(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.UserPoolData memory userPoolData;
        IERC20Metadata token = IERC20Metadata(_reserve);

        userPoolData.juniorTrancheBalance = lmp.balance(
            _reserve,
            _user,
            ReserveLogic.Tranche.JUNIOR
        );
        userPoolData.seniorTrancheBalance = lmp.balance(
            _reserve,
            _user,
            ReserveLogic.Tranche.SENIOR
        );
        userPoolData.withdrawableJuniorTrancheBalance = lmp.withdrawAbleAmount(
            _reserve,
            _user,
            ReserveLogic.Tranche.JUNIOR
        );
        userPoolData.withdrawableSeniorTrancheBalance = lmp.withdrawAbleAmount(
            _reserve,
            _user,
            ReserveLogic.Tranche.SENIOR
        );
        userPoolData.decimals = token.decimals();

        return userPoolData;
    }

    function getVaultData(
        address _user,
        address _reserve,
        address _sponsor
    ) external view returns (DataTypes.VaultData memory) {
        DataTypes.VaultData memory vaultData;
        address vault = IVaultManagerProxy(
            addressResolver.getVaultManagerProxy()
        ).getVault(_user);
        IVaultManagerProxy vmp = IVaultManagerProxy(
            addressResolver.getVaultManagerProxy()
        );
        IStableDebtToken debtToken = IStableDebtToken(
            addressResolver.getStableDebtToken()
        );
        vaultData.borrowRate = debtToken.getAverageStableRate();
        vaultData.totalDebt = IERC20(addressResolver.getStableDebtToken())
            .balanceOf(_user);
        vaultData.totalSecurityDeposit = vmp.getSecurityDeposit(
            _user,
            _reserve
        );
        vaultData.withdrawableSecurityDeposit = vmp.getWithdrawableDeposit(
            _user,
            _reserve,
            _sponsor
        );
        vaultData.gav = vmp.getGav(_user);
        vaultData.totalSecurityDeposit = vmp.getSecurityDeposit(
            _user,
            _reserve
        );
        vaultData.creditLimit = vmp.getCreditLimit(_user, _reserve);
        vaultData.spendableBalance = vmp.getAvailableCredit(_user, _reserve);
        vaultData.optimalAggregateRepaymentRate = debtToken
            .getAggregateOptimalRepaymentRate(vault);
        vaultData.actualAggregateRepaymentRate = debtToken
            .getAggregateActualRepaymentRate(vault);
        vaultData.ltv = vaultData
            .gav
            .add(vaultData.totalSecurityDeposit)
            .rayDiv(vaultData.totalDebt);
        DataTypes.HealthRiskParameter memory hrp;
        hrp.securityDeposit = vaultData.totalSecurityDeposit;
        hrp.currentBorrowRate = vaultData.borrowRate;
        hrp.compoundedDebt = vaultData.totalDebt;
        hrp.grossAssetValue = vaultData.gav;
        hrp.aggregateOptimalRepaymentRate = vaultData
            .optimalAggregateRepaymentRate;
        hrp.aggregateActualRepaymentRate = vaultData
            .actualAggregateRepaymentRate;

        IReserveManager rm = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(_reserve);
        IHealthStrategy hs = IHealthStrategy(reserve.healthStrategyAddress);
        vaultData.healthFactor = hs.calculateHealthRisk(hrp);
        return vaultData;
    }
}

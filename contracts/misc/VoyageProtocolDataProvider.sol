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
import '../component/liquiditymanager/LiquidityManager.sol';
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
        poolConfiguration.securityRequirement = vm
            .getSecurityDepositRequirement(_reserve);
        poolConfiguration.minSecurity = vm.getMinSecurityDeposit(_reserve);
        poolConfiguration.maxSecurity = vm.getMaxSecurityDeposit(_reserve);
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
        poolData.totalDebt = reserve.totalBorrows;
        poolData.borrowRate = reserve.currentBorrowRate;
        poolData.trancheRatio = depositAndDebt.juniorDepositAmount.rayDiv(
            depositAndDebt.seniorDepositAmount
        );

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

    function getVaultData(
        address _user,
        address _reserve,
        address _sponsor
    ) external view returns (DataTypes.VaultData memory) {
        DataTypes.VaultData memory vaultData;
        IVaultManagerProxy vmp = IVaultManagerProxy(
            addressResolver.getVaultManagerProxy()
        );
        vaultData.borrowRate = 0;
        vaultData.totalDebt = 0;
        vaultData.totalSecurityDeposit = vmp.getSecurityDeposit(
            _user,
            _reserve
        );
        vaultData.withdrawableSecurityDeposit = vmp.eligibleAmount(
            _user,
            _reserve,
            _sponsor
        );
        return vaultData;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/IReserveManager.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../libraries/types/DataTypes.sol';
import '../interfaces/IVaultManager.sol';
import '../interfaces/IHealthStrategy.sol';
import '../interfaces/IVaultManagerProxy.sol';
import '../interfaces/ILiquidityManagerProxy.sol';
import '../component/liquiditymanager/LiquidityManager.sol';

contract VoyageProtocolDataProvider {
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
        returns (
            uint256 totalLiquidity,
            uint256 juniorLiquidity,
            uint256 seniorLiquidity,
            uint256 juniorLiquidityRate,
            uint256 seniorLiquidityRate,
            uint256 totalDebt,
            uint256 borrowRate,
            uint256 trancheRatio
        )
    {
        IReserveManager rm = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(
            underlyingAsset
        );
        ILiquidityManagerProxy lmp = ILiquidityManagerProxy(
            addressResolver.getVaultManagerProxy()
        );
        uint256 _juniorLiquidity = lmp
            .getLiquidityAndDebt(underlyingAsset)
            .juniorDepositAmount;
        uint256 _seniorLiquidity = lmp
            .getLiquidityAndDebt(underlyingAsset)
            .seniorDepositAmount;
        uint256 _totalLiquidity = juniorLiquidity + seniorLiquidity;
        return (
            _totalLiquidity,
            _juniorLiquidity,
            _seniorLiquidity,
            0,
            0,
            reserve.totalBorrows,
            reserve.currentBorrowRate,
            0
        );
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
}

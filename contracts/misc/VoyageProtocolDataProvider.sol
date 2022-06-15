// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IAddressResolver} from "../interfaces/IAddressResolver.sol";
import {IReserveManager} from "../interfaces/IReserveManager.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IVaultManager} from "../interfaces/IVaultManager.sol";
import {IHealthStrategy} from "../interfaces/IHealthStrategy.sol";
import {IVaultManagerProxy} from "../interfaces/IVaultManagerProxy.sol";
import {IVToken} from "../interfaces/IVToken.sol";
import {ILiquidityManagerProxy} from "../interfaces/ILiquidityManagerProxy.sol";
import {ILoanManagerProxy} from "../interfaces/ILoanManagerProxy.sol";
import {LiquidityManager} from "../component/liquidity/LiquidityManager.sol";
import "hardhat/console.sol";

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
        ILiquidityManagerProxy lmp = ILiquidityManagerProxy(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(_reserve);
        address healthStrategyAddr = reserve.healthStrategyAddress;
        require(healthStrategyAddr != address(0), "invalid health strategy");
        IHealthStrategy hs = IHealthStrategy(healthStrategyAddr);
        DataTypes.VaultConfig memory vc = vm.getVaultConfig(_reserve);
        poolConfiguration.securityRequirement = vc.securityDepositRequirement;
        poolConfiguration.minSecurity = vc.minSecurityDeposit;
        poolConfiguration.maxSecurity = vc.maxSecurityDeposit;
        poolConfiguration.loanTenure = hs.getLoanTenure();
        poolConfiguration.optimalIncomeRatio = reserve.optimalIncomeRatio;
        poolConfiguration.optimalTrancheRatio = reserve.optimalTrancheRatio;
        (bool isActive, , ) = lmp.getFlags(_reserve);
        poolConfiguration.isActive = isActive;

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
        if (depositAndDebt.seniorDepositAmount == 0) {
            poolData.trancheRatio = 0;
        } else {
            poolData.trancheRatio = depositAndDebt.juniorDepositAmount.rayDiv(
                depositAndDebt.seniorDepositAmount
            );
        }

        poolData.decimals = token.decimals();
        poolData.utilizationRate = lmp.utilizationRate(underlyingAsset);
        poolData.symbol = token.symbol();
        (bool isActive, , ) = lmp.getFlags(underlyingAsset);
        poolData.isActive = isActive;

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

        uint256 seniorTrancheWithdrawable = lmp.balance(
            _reserve,
            _user,
            ReserveLogic.Tranche.SENIOR
        );
        uint256 seniorTrancheUnbonding = lmp.unbonding(
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
        ILoanManagerProxy lmp = ILoanManagerProxy(
            addressResolver.getLoanManagerProxy()
        );
        uint256 principal;
        uint256 interest;
        DataTypes.DrawDownList memory drawDownList;
        (drawDownList.head, drawDownList.tail) = lmp.getDrawDownList(
            _reserve,
            vault
        );
        (principal, interest) = lmp.getVaultDebt(_reserve, vault);
        vaultData.drawDownList = drawDownList;
        vaultData.borrowRate = 0;
        vaultData.totalDebt = principal.add(interest);
        vaultData.totalSecurityDeposit = vmp.getSecurityDeposit(
            _user,
            _reserve
        );
        vaultData.withdrawableSecurityDeposit = vmp.getWithdrawableDeposit(
            _user,
            _reserve,
            _sponsor
        );
        vaultData.totalSecurityDeposit = vmp.getSecurityDeposit(
            _user,
            _reserve
        );
        vaultData.creditLimit = vmp.getCreditLimit(_user, _reserve);
        vaultData.spendableBalance = vmp.getAvailableCredit(_user, _reserve);
        vaultData.ltv = vaultData
            .gav
            .add(vaultData.totalSecurityDeposit)
            .rayDiv(vaultData.totalDebt);

        IReserveManager rm = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(_reserve);
        return vaultData;
    }

    function getDrawDownDetail(
        address _user,
        address _reserve,
        uint256 _drawDownId
    ) external view returns (DataTypes.DebtDetail memory) {
        ILoanManagerProxy lmp = ILoanManagerProxy(
            addressResolver.getLoanManagerProxy()
        );
        address vault = IVaultManagerProxy(
            addressResolver.getVaultManagerProxy()
        ).getVault(_user);
        return lmp.getDrawDownDetail(_reserve, vault, _drawDownId);
    }

    function pendingSeniorWithdrawals(address _user, address _reserve)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        IReserveManager rm = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(_reserve);

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
        IReserveManager rm = IReserveManager(
            addressResolver.getLiquidityManagerProxy()
        );
        DataTypes.ReserveData memory reserve = rm.getReserveData(_reserve);

        (uint256[] memory times, uint256[] memory amounts) = IVToken(
            reserve.juniorDepositTokenAddress
        ).unbonding(_user);

        return (times, amounts);
    }
}

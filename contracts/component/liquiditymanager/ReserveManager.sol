// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../Voyager.sol';
import '../../libraries/helpers/Errors.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import './LiquidityManagerStorage.sol';
import '../infra/AddressResolver.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../interfaces/IDebtToken.sol';
import '../../libraries/logic/ReserveLogic.sol';
import '../../interfaces/IReserveManager.sol';

contract ReserveManager is Proxyable, IReserveManager {
    Voyager public voyager;

    constructor(address payable _proxy, address _voyager)
        public
        Proxyable(_proxy)
    {
        voyager = Voyager(_voyager);
    }

    function initReserve(
        address _asset,
        address _juniorDepositTokenAddress,
        address _seniorDepositTokenAddress,
        uint256 _juniorIncomeAllocation,
        uint256 _seniorIncomeAllocation,
        address _stableDebtAddress,
        address _interestRateStrategyAddress
    ) external onlyProxy {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        LiquidityManagerStorage(liquidityManagerStorageAddress()).initReserve(
            _asset,
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _juniorIncomeAllocation,
            _seniorIncomeAllocation,
            _stableDebtAddress,
            _interestRateStrategyAddress
        );
    }

    function getReserveData(address _asset)
        public
        view
        returns (DataTypes.ReserveData memory)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getReserveData(_asset);
    }

    function getConfiguration(address _asset)
        public
        view
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getConfiguration(_asset);
    }

    function getLiquidityRate(address _asset, ReserveLogic.Tranche _tranche)
        public
        view
        returns (uint256)
    {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        return
            LiquidityManagerStorage(liquidityManagerStorageAddress())
                .getLiquidityRate(_asset, _tranche);
    }

    function liquidityManagerStorageAddress() internal view returns (address) {
        return
            AddressResolver(voyager.getAddressResolverAddress()).getAddress(
                voyager.getLiquidityManagerStorageName()
            );
    }
}

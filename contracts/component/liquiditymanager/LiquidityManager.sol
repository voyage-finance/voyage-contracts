// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxyable.sol';
import '../../libraries/helpers/Errors.sol';
import '../Voyager.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import './LiquidityManagerStorage.sol';
import '../infra/AddressResolver.sol';

contract LiquidityManager is Proxyable {
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
        address _stableDebtAddress,
        address _interestRateStrategyAddress
    ) external onlyProxy {
        require(Address.isContract(_asset), Errors.LM_NOT_CONTRACT);
        address liquidityManagerStorageAddress = AddressResolver(
            voyager.getAddressResolverAddress()
        ).getAddress(voyager.getLiquidityManagerStorageName());
        LiquidityManagerStorage(liquidityManagerStorageAddress).initReserve(
            _asset,
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _stableDebtAddress,
            _interestRateStrategyAddress
        );
    }
}

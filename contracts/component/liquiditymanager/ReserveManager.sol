// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../Voyager.sol';
import '../../libraries/helpers/Errors.sol';
import 'openzeppelin-solidity/contracts/utils/Address.sol';
import './LiquidityManagerStorage.sol';
import '../infra/AddressResolver.sol';
import '../../libraries/proxy/Proxyable.sol';
import '../../libraries/logic/ReserveLogic.sol';

contract ReserveManager is Proxyable {
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
        LiquidityManagerStorage(liquidityManagerStorageAddress()).initReserve(
            _asset,
            _juniorDepositTokenAddress,
            _seniorDepositTokenAddress,
            _stableDebtAddress,
            _interestRateStrategyAddress
        );
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

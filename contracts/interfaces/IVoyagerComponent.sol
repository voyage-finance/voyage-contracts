// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../component/Voyager.sol';
import '../component/infra/AddressResolver.sol';

abstract contract IVoyagerComponent {
    Voyager public voyager;

    function liquidityManagerStorageAddress() internal view returns (address) {
        return
            AddressResolver(voyager.getAddressResolverAddress()).getAddress(
                voyager.getLiquidityManagerStorageName()
            );
    }
}

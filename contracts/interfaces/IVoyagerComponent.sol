// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Voyager} from "../component/Voyager.sol";
import {AddressResolver} from "../component/infra/AddressResolver.sol";
import {LiquidityManagerStorage} from "../component/shared/storage/LiquidityManagerStorage.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

abstract contract IVoyagerComponent {
    Voyager public voyager;

    modifier requireNotPaused() {
        _whenNotPaused();
        _;
    }

    function liquidityManagerStorageAddress() internal view returns (address) {
        return
            AddressResolver(voyager.getAddressResolverAddress())
                .getLiquidityManagerStorage();
    }

    function getPriceOracleAddress() internal view returns (address) {
        return
            AddressResolver(voyager.getAddressResolverAddress())
                .getPriceOracle();
    }

    function _whenNotPaused() internal view {
        require(!paused(), Errors.LP_IS_PAUSED);
    }

    function paused() internal view returns (bool) {
        address storageAddress = liquidityManagerStorageAddress();
        return LiquidityManagerStorage(storageAddress).paused();
    }

    function getDepositAndDebt(address _reserve)
        public
        view
        returns (DataTypes.DepositAndDebt memory)
    {
        address storageAddress = liquidityManagerStorageAddress();
        return
            LiquidityManagerStorage(storageAddress).getDepositAndDebt(_reserve);
    }
}

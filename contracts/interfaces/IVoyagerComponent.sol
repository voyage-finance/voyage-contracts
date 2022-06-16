// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Voyager} from "../component/Voyager.sol";
import {AddressResolver} from "../component/infra/AddressResolver.sol";
// import {LiquidityManagerStorage} from "../component/shared/storage/LiquidityManagerStorage.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

abstract contract IVoyagerComponent {
    Voyager public voyager;

    function getPriceOracleAddress() internal view returns (address) {
        return address(0);
    }
}

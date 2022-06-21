// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Voyager} from "../component/Voyager.sol";

abstract contract IVoyagerComponent {
    Voyager public voyager;

    function getPriceOracleAddress() internal view returns (address) {
        return address(0);
    }
}

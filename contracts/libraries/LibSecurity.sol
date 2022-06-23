// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

library LibSecurity {
    function isAuthorised(
        address src,
        address dst,
        bytes4 sig
    ) internal returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

bytes32 constant ADDRESS_RESOLVER = "address_resolver";

struct AppStorage {
    mapping(bytes32 => address) _addresses;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

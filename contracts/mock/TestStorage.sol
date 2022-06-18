// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

struct Storage {
    uint256 principalBalance;
    uint256 interestBalance;
}

contract TestStorage {
    function testStorage() internal pure returns (Storage storage s) {
        bytes32 pos = keccak256("finance.voyage.storage.mock");
        assembly {
            s.slot := pos
        }
    }
}

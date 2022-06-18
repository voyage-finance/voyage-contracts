// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Storage, TestStorage} from "./TestStorage.sol";

contract TestInitDiamond is TestStorage {
    struct Args {
        uint256 principalBalance;
        uint256 interestBalance;
    }

    function init(Args memory args) public {
        Storage storage s = testStorage();
        s.principalBalance = args.principalBalance;
        s.interestBalance = args.interestBalance;
    }
}

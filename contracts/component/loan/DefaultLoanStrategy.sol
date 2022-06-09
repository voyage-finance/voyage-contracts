// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ILoanStrategy} from "../../interfaces/ILoanStrategy.sol";

contract DefaultLoanStrategy is ILoanStrategy {
    uint256 public immutable term;

    uint256 public immutable epoch;

    constructor(uint256 _term, uint256 _epoch) public {
        term = _term;
        epoch = _epoch;
    }

    function getTerm() external view returns (uint256) {
        return term;
    }

    function getEpoch() external view returns (uint256) {
        return epoch;
    }
}

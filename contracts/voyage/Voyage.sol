// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Diamond} from "../shared/diamond/Diamond.sol";
import {LibDiamond} from "../shared/diamond/libraries/LibDiamond.sol";

contract Voyage is Diamond {
    constructor(address _owner) Diamond(_owner) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Diamond} from "../diamond/Diamond.sol";
import {LibDiamond} from "../diamond/libraries/LibDiamond.sol";

contract Voyager is Diamond {
    constructor(address _owner) Diamond(_owner) {}
}

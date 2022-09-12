// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Diamond} from "../shared/diamond/Diamond.sol";
import {LibDiamond} from "../shared/diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../shared/diamond/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../shared/diamond/interfaces/IDiamondCut.sol";
import {IERC173} from "../shared/diamond/interfaces/IERC173.sol";
import {IERC165} from "../shared/diamond/interfaces/IERC165.sol";

contract Voyage is Diamond {
    constructor(address _owner) Diamond(_owner) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }
}

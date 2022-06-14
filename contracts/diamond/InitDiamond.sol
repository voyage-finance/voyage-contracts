// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {AppStorage, ADDRESS_RESOLVER} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../diamond/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../diamond/interfaces/IDiamondCut.sol";
import {IERC173} from "../diamond/interfaces/IERC173.sol";
import {IERC165} from "../diamond/interfaces/IERC165.sol";

contract InitDiamond {
    AppStorage internal s;

    struct Args {
        address addressResolver;
    }

    function init(Args memory _args) external {
        // initialise diamond level stuff
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // initialise app storage stuff
        s._addresses[ADDRESS_RESOLVER] = _args.addressResolver;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../diamond/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../diamond/interfaces/IDiamondCut.sol";
import {IERC173} from "../diamond/interfaces/IERC173.sol";
import {IERC165} from "../diamond/interfaces/IERC165.sol";
import {DSRoles} from "../component/auth/DSRoles.sol";
import {DSGuard} from "../component/auth/DSGuard.sol";
import "hardhat/console.sol";

contract InitDiamond {
    AppStorage internal s;

    struct Args {
        address initOwner;
    }

    function init(Args memory _args) external {
        // initialise diamond level stuff
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // initialise app storage stuff
        s._paused = false;
        if (address(s.auth.rbac) == address(0)) {
            s.auth.rbac = new DSRoles();
        }
        if (address(s.auth.acl) == address(0)) {
            s.auth.acl = new DSGuard();
            s.auth.rbac.setRootUser(_args.initOwner, true);
            bytes32 ANY = bytes32(type(uint256).max);
            s.auth.acl.permit(bytes32(bytes20(_args.initOwner)), ANY, ANY);
        }
    }
}

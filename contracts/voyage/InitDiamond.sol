// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {AppStorage, LibAppStorage} from "./libraries/LibAppStorage.sol";
import {DSRoles} from "../voyage/auth/DSRoles.sol";
import {DSGuard} from "../voyage/auth/DSGuard.sol";
import {IWETH9} from "../shared/libraries/LibPayments.sol";

contract InitDiamond {
    struct Args {
        address initOwner;
        address seniorDepositTokenImpl;
        address juniorDepositTokenImpl;
        address vaultImpl;
        address weth9;
    }

    function init(Args memory _args) external {
        // initialise app storage stuff
        AppStorage storage s = LibAppStorage.ds();
        s.WETH9 = IWETH9(_args.weth9);
        s._paused = false;
        if (address(LibAppStorage.ds().auth.rbac) == address(0)) {
            s.auth.rbac = new DSRoles();
        }
        if (address(LibAppStorage.ds().auth.acl) == address(0)) {
            s.auth.acl = new DSGuard();
            s.auth.rbac.setRootUser(_args.initOwner, true);
            bytes32 ANY = bytes32(type(uint256).max);
            s.auth.acl.permit(bytes32(bytes20(_args.initOwner)), ANY, ANY);
            s.auth.acl.permit(bytes32(bytes20(address(this))), ANY, ANY);
        }

        if (address(s.seniorDepositTokenBeacon) == address(0)) {
            s.seniorDepositTokenBeacon = new UpgradeableBeacon(
                _args.seniorDepositTokenImpl
            );
        }

        if (address(s.juniorDepositTokenBeacon) == address(0)) {
            s.juniorDepositTokenBeacon = new UpgradeableBeacon(
                _args.juniorDepositTokenImpl
            );
        }

        if (address(s.vaultBeacon) == address(0)) {
            s.vaultBeacon = new UpgradeableBeacon(_args.vaultImpl);
        }
    }
}

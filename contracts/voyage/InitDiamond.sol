// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {AppStorage} from "./libraries/LibAppStorage.sol";
import {LibDiamond} from "../shared/diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../shared/diamond/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../shared/diamond/interfaces/IDiamondCut.sol";
import {IERC173} from "../shared/diamond/interfaces/IERC173.sol";
import {IERC165} from "../shared/diamond/interfaces/IERC165.sol";
import {DSRoles} from "../voyage/auth/DSRoles.sol";
import {DSGuard} from "../voyage/auth/DSGuard.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";

contract InitDiamond {
    AppStorage internal s;

    struct Args {
        address initOwner;
        address marginEscrowImpl;
        address creditEscrowImpl;
        address seniorDepositTokenImpl;
        address juniorDepositTokenImpl;
        address vaultFactory;
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

        if (address(s.marginEscrowBeacon) == address(0)) {
            s.marginEscrowBeacon = new UpgradeableBeacon(
                _args.marginEscrowImpl
            );
        }

        if (address(s.creditEscrowBeacon) == address(0)) {
            s.creditEscrowBeacon = new UpgradeableBeacon(
                _args.creditEscrowImpl
            );
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

        if (address(s.vaultFactory) == address(0)) {
            s.vaultFactory = IVaultFactory(_args.vaultFactory);
        }
    }
}

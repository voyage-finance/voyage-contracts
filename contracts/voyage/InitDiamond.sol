// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {AppStorage, LibAppStorage} from "./libraries/LibAppStorage.sol";
import {LibDiamond} from "../shared/diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../shared/diamond/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../shared/diamond/interfaces/IDiamondCut.sol";
import {IERC173} from "../shared/diamond/interfaces/IERC173.sol";
import {IERC165} from "../shared/diamond/interfaces/IERC165.sol";
import {IWETH9} from "../shared/facets/PaymentsFacet.sol";
import {DSRoles} from "../voyage/auth/DSRoles.sol";
import {DSGuard} from "../voyage/auth/DSGuard.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";

contract InitDiamond {
    struct Args {
        address initOwner;
        address seniorDepositTokenImpl;
        address juniorDepositTokenImpl;
        address vaultFactory;
        address diamondCutFacet;
        address diamondLoupeFacet;
        address ownershipFacet;
        address weth9;
    }

    function init(Args memory _args) external {
        // initialise diamond level stuff
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // initialise app storage stuff
        LibAppStorage.ds().WETH9 = IWETH9(_args.weth9);
        LibAppStorage.ds()._paused = false;
        if (address(LibAppStorage.ds().auth.rbac) == address(0)) {
            LibAppStorage.ds().auth.rbac = new DSRoles();
        }
        if (address(LibAppStorage.ds().auth.acl) == address(0)) {
            LibAppStorage.ds().auth.acl = new DSGuard();
            LibAppStorage.ds().auth.rbac.setRootUser(_args.initOwner, true);
            bytes32 ANY = bytes32(type(uint256).max);
            LibAppStorage.ds().auth.acl.permit(
                bytes32(bytes20(_args.initOwner)),
                ANY,
                ANY
            );
        }

        if (
            address(LibAppStorage.ds().seniorDepositTokenBeacon) == address(0)
        ) {
            LibAppStorage.ds().seniorDepositTokenBeacon = new UpgradeableBeacon(
                _args.seniorDepositTokenImpl
            );
        }

        if (
            address(LibAppStorage.ds().juniorDepositTokenBeacon) == address(0)
        ) {
            LibAppStorage.ds().juniorDepositTokenBeacon = new UpgradeableBeacon(
                _args.juniorDepositTokenImpl
            );
        }

        if (address(LibAppStorage.ds().vaultFactory) == address(0)) {
            LibAppStorage.ds().vaultFactory = IVaultFactory(_args.vaultFactory);
        }

        if (LibAppStorage.ds().diamondFacet.diamondCutFacet == address(0)) {
            LibAppStorage.ds().diamondFacet.diamondCutFacet = _args
                .diamondCutFacet;
        }

        if (LibAppStorage.ds().diamondFacet.diamondLoupeFacet == address(0)) {
            LibAppStorage.ds().diamondFacet.diamondLoupeFacet = _args
                .diamondLoupeFacet;
        }

        if (LibAppStorage.ds().diamondFacet.ownershipFacet == address(0)) {
            LibAppStorage.ds().diamondFacet.ownershipFacet = _args
                .ownershipFacet;
        }
    }
}

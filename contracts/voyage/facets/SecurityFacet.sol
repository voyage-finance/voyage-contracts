// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Storage, Authorisation, LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibSecurity} from "../libraries/LibSecurity.sol";
import {VaultFacet} from "./VaultFacet.sol";

contract SecurityFacet is Storage {
    using LibSecurity for Authorisation;

    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool) {
        return LibAppStorage.ds()._paused;
    }

    function pause() public authorised {
        LibAppStorage.ds()._paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public authorised {
        LibAppStorage.ds()._paused = false;
        emit Unpaused(_msgSender());
    }

    function grantRole(
        address user,
        uint8 role,
        bool enabled
    ) public authorised {
        LibSecurity.grantRole(LibAppStorage.ds().auth, user, role, enabled);
    }

    function grantRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public authorised {
        LibSecurity.grantRolePermission(
            LibAppStorage.ds().auth,
            role,
            target,
            sig
        );
    }

    function revokeRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public authorised {
        LibSecurity.revokeRolePermission(
            LibAppStorage.ds().auth,
            role,
            target,
            sig
        );
    }

    function grantPermission(
        address src,
        address dst,
        bytes4 sig
    ) public authorised {
        LibSecurity.grantPermission(LibAppStorage.ds().auth, src, dst, sig);
    }

    function revokePermission(
        address src,
        address dst,
        bytes4 sig
    ) public authorised {
        LibSecurity.revokePermission(LibAppStorage.ds().auth, src, dst, sig);
    }

    function isAuthorisedInbound(address src, bytes4 sig)
        public
        returns (bool)
    {
        return
            LibSecurity.isAuthorisedInbound(LibAppStorage.ds().auth, src, sig);
    }

    function isAuthorisedOutbound(address dst, bytes4 sig)
        public
        returns (bool)
    {
        return
            LibSecurity.isAuthorisedOutbound(LibAppStorage.ds().auth, dst, sig);
    }

    function isAuthorised(
        address src,
        address dst,
        bytes4 sig
    ) public returns (bool) {
        return LibSecurity.isAuthorised(LibAppStorage.ds().auth, src, dst, sig);
    }
}

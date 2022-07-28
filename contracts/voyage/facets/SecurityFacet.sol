// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Storage, Authorisation} from "../libraries/LibAppStorage.sol";
import {LibSecurity} from "../libraries/LibSecurity.sol";
import {VaultFacet} from "./VaultFacet.sol";

contract SecurityFacet is Storage {
    using LibSecurity for Authorisation;

    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool) {
        return s._paused;
    }

    function pause() public authorised {
        s._paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public authorised {
        s._paused = false;
        emit Unpaused(_msgSender());
    }

    function grantRole(
        address user,
        uint8 role,
        bool enabled
    ) public authorised {
        LibSecurity.grantRole(s.auth, user, role, enabled);
    }

    function grantRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public authorised {
        LibSecurity.grantRolePermission(s.auth, role, target, sig);
    }

    function revokeRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public authorised {
        LibSecurity.revokeRolePermission(s.auth, role, target, sig);
    }

    function grantPermission(
        address src,
        address dst,
        bytes4 sig
    ) public authorised {
        LibSecurity.grantPermission(s.auth, src, dst, sig);
    }

    function revokePermission(
        address src,
        address dst,
        bytes4 sig
    ) public authorised {
        LibSecurity.revokePermission(s.auth, src, dst, sig);
    }

    function isAuthorisedInbound(address src, bytes4 sig)
        public
        returns (bool)
    {
        return LibSecurity.isAuthorisedInbound(s.auth, src, sig);
    }

    function isAuthorisedOutbound(address dst, bytes4 sig)
        public
        returns (bool)
    {
        return LibSecurity.isAuthorisedOutbound(s.auth, dst, sig);
    }

    function isAuthorised(
        address src,
        address dst,
        bytes4 sig
    ) public returns (bool) {
        return LibSecurity.isAuthorised(s.auth, src, dst, sig);
    }
}

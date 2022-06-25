// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Storage, Authorisation} from "../../libraries/LibAppStorage.sol";
import {LibSecurity} from "../../libraries/LibSecurity.sol";
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
        s.auth.grantRole(user, role, enabled);
    }

    function grantRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public authorised {
        s.auth.grantRolePermission(role, target, sig);
    }

    function revokeRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public authorised {
        s.auth.revokeRolePermission(role, target, sig);
    }

    function grantPermission(
        address src,
        address dst,
        bytes4 sig
    ) public authorised {
        s.auth.grantPermission(src, dst, sig);
    }

    function revokePermission(
        address src,
        address dst,
        bytes4 sig
    ) public authorised {
        s.auth.revokePermission(src, dst, sig);
    }

    function isAuthorisedInbound(address src, bytes4 sig)
        public
        returns (bool)
    {
        return s.auth.isAuthorisedInbound(src, sig);
    }

    function isAuthorisedOutbound(address dst, bytes4 sig)
        public
        returns (bool)
    {
        return s.auth.isAuthorisedOutbound(dst, sig);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {DSRoles} from "../component/auth/DSRoles.sol";
import {DSGuard} from "../component/auth/DSGuard.sol";

library LibSecurity {
    struct Security {
        DSRoles rbac;
        DSGuard acl;
    }

    function isAuthorised(
        address src,
        address dst,
        bytes4 sig
    ) internal returns (bool) {
        return false;
    }

    function isAuthorisedInbound(
        Security memory security,
        address src,
        bytes4 selector
    ) internal view returns (bool) {
        // s.security.acl/rbac is an instance ds-roles and implements DSAuthority interface
        return
            security.rbac.canCall(src, address(this), selector) ||
            security.acl.canCall(src, address(this), selector);
    }

    function isAuthorisedOutbound(
        Security memory security,
        address dst,
        bytes4 selector
    ) internal view returns (bool) {
        // s.security.acl/rbac is an instance ds-guard and implements DSAuthority interface
        return
            security.rbac.canCall(msg.sender, dst, selector) ||
            security.acl.canCall(msg.sender, dst, selector);
    }

    // role can be a enum, but cast to uint8 before calling grantRole
    function grantRole(
        Security memory security,
        address user,
        uint8 role,
        bool enabled
    ) internal {
        // grant role
        security.rbac.setUserRole(user, role, enabled);
    }

    function grantRolePermission(
        Security memory security,
        uint8 role,
        address target,
        bytes4 sig
    ) internal {
        // give a role a permission
        security.rbac.setRoleCapability(role, target, sig, true);
    }

    function revokeRolePermission(
        Security memory security,
        uint8 role,
        address target,
        bytes4 sig
    ) internal {
        // revoke a role permission
        security.rbac.setRoleCapability(role, target, sig, false);
    }

    function grantPermission(
        Security memory security,
        address src,
        address dst,
        bytes4 sig
    ) internal {
        // allow src to call dst.sig
        security.acl.permit(src, dst, sig);
    }

    function revokePermission(
        Security memory security,
        address src,
        address dst,
        bytes4 sig
    ) internal {
        security.acl.forbid(src, dst, sig);
    }
}

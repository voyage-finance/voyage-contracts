// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibAppStorage, AppStorage, Authorisation} from "./LibAppStorage.sol";

library LibSecurity {
    function isAuthorised(
        Authorisation storage auth,
        address src,
        address dst,
        bytes4 selector
    ) internal view returns (bool) {
        return
            auth.rbac.canCall(src, dst, selector) ||
            auth.acl.canCall(src, dst, selector);
    }

    function isAuthorisedInbound(
        Authorisation storage auth,
        address src,
        bytes4 selector
    ) internal view returns (bool) {
        // s.security.acl/rbac is an instance ds-roles and implements DSAuthority interface
        return
            auth.rbac.canCall(src, address(this), selector) ||
            auth.acl.canCall(src, address(this), selector);
    }

    function isAuthorisedOutbound(
        Authorisation storage auth,
        address dst,
        bytes4 selector
    ) internal view returns (bool) {
        // s.security.acl/rbac is an instance ds-guard and implements DSAuthority interface
        return
            auth.rbac.canCall(msg.sender, dst, selector) ||
            auth.acl.canCall(msg.sender, dst, selector);
    }

    // role can be a enum, but cast to uint8 before calling grantRole
    function grantRole(
        Authorisation storage auth,
        address user,
        uint8 role,
        bool enabled
    ) internal {
        // grant role
        auth.rbac.setUserRole(user, role, enabled);
    }

    function grantRolePermission(
        Authorisation storage auth,
        uint8 role,
        address target,
        bytes4 sig
    ) internal {
        // give a role a permission
        auth.rbac.setRoleCapability(role, target, sig, true);
    }

    function revokeRolePermission(
        Authorisation storage auth,
        uint8 role,
        address target,
        bytes4 sig
    ) internal {
        // revoke a role permission
        auth.rbac.setRoleCapability(role, target, sig, false);
    }

    function grantPermissions(
        Authorisation storage auth,
        address src,
        address dst,
        bytes4[] memory sig
    ) internal {
        for (uint256 i = 0; i < sig.length; i++) {
            grantPermission(auth, src, dst, sig[i]);
        }
    }

    function grantPermission(
        Authorisation storage auth,
        address src,
        address dst,
        bytes4 sig
    ) internal {
        // allow src to call dst.sig
        auth.acl.permit(src, dst, sig);
    }

    function revokePermission(
        Authorisation storage auth,
        address src,
        address dst,
        bytes4 sig
    ) internal {
        auth.acl.forbid(src, dst, sig);
    }
}

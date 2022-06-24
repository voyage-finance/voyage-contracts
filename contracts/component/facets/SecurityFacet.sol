// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Storage} from "../../libraries/LibAppStorage.sol";
import {LibSecurity} from "../../libraries/LibSecurity.sol";

abstract contract Authz {
    using LibSecurity for LibSecurity.Security;

    LibSecurity.Security security;

    modifier auth() {
        require(
            security.isAuthorisedInbound(msg.sender, msg.sig),
            "call is not authorised"
        );
        _;
    }
}

contract SecurityFacet is Storage, Authz {
    using LibSecurity for LibSecurity.Security;

    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool) {
        return s._paused;
    }

    function pause() public onlyAdmin {
        s._paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyAdmin {
        s._paused = false;
        emit Unpaused(_msgSender());
    }

    function grantRole(
        address user,
        uint8 role,
        bool enabled
    ) public auth {
        security.grantRole(user, role, enabled);
    }

    function grantRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public auth {
        security.grantRolePermission(role, target, sig);
    }

    function revokeRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) public auth {
        security.revokeRolePermission(role, target, sig);
    }

    function grantPermission(
        address src,
        address dst,
        bytes4 sig
    ) public auth {
        security.grantPermission(src, dst, sig);
    }

    function revokePermission(
        address src,
        address dst,
        bytes4 sig
    ) public auth {
        security.revokePermission(src, dst, sig);
    }

    function isAuthorisedInbound(address src, bytes4 sig)
        public
        returns (bool)
    {
        return security.isAuthorisedInbound(src, sig);
    }

    function isAuthorisedOutbound(address dst, bytes4 sig)
        public
        returns (bool)
    {
        return security.isAuthorisedOutbound(dst, sig);
    }
}

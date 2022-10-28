// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ISecurityFacet {
    function pause() external;

    function unpause() external;

    function grantRole(
        address user,
        uint8 role,
        bool enabled
    ) external;

    function grantRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) external;

    function revokeRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) external;

    function grantPermission(
        address src,
        address dst,
        bytes4 sig
    ) external;

    function authorizeConfigurator(address _configurator) external;

    function revokePermission(
        address src,
        address dst,
        bytes4 sig
    ) external;

    function isAuthorisedInbound(address src, bytes4 sig)
        external
        view
        returns (bool);

    function isAuthorisedOutbound(address dst, bytes4 sig)
        external
        view
        returns (bool);

    function isAuthorised(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);

    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool);

    function paused() external view returns (bool);
}

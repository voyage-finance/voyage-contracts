// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Storage, Authorisation, LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibSecurity} from "../libraries/LibSecurity.sol";
import {ILiquidityFacet} from "../interfaces/ILiquidityFacet.sol";
import {ISecurityFacet} from "../interfaces/ISecurityFacet.sol";
import {ConfigurationFacet} from "../facets/ConfigurationFacet.sol";
import {OracleFacet} from "../facets/OracleFacet.sol";

contract SecurityFacet is Storage, ISecurityFacet {
    using LibSecurity for Authorisation;

    event Paused(address account);
    event Unpaused(address account);
    event RoleGranted(address user, uint8 role, bool enabled);
    event RolePermissionGranted(uint8 role, address target, bytes4 sig);
    event PermissionGranted(address src, address dst, bytes4 sig);
    event RoleRevoked(address user, uint8 role);
    event RolePermissionRevoked(uint8 role, address target, bytes4 sig);
    event PermissionRevoked(address src, address dst, bytes4 sig);

    function pause() external authorised {
        LibAppStorage.ds()._paused = true;
        emit Paused(_msgSender());
    }

    function unpause() external authorised {
        LibAppStorage.ds()._paused = false;
        emit Unpaused(_msgSender());
    }

    function grantRole(
        address user,
        uint8 role,
        bool enabled
    ) external authorised {
        LibSecurity.grantRole(LibAppStorage.ds().auth, user, role, enabled);
        emit RoleGranted(user, role, enabled);
    }

    function grantRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) external authorised {
        LibSecurity.grantRolePermission(
            LibAppStorage.ds().auth,
            role,
            target,
            sig
        );
        emit RolePermissionGranted(role, target, sig);
    }

    function revokeRolePermission(
        uint8 role,
        address target,
        bytes4 sig
    ) external authorised {
        LibSecurity.revokeRolePermission(
            LibAppStorage.ds().auth,
            role,
            target,
            sig
        );
        emit RolePermissionRevoked(role, target, sig);
    }

    function grantPermission(
        address src,
        address dst,
        bytes4 sig
    ) external authorised {
        LibSecurity.grantPermission(LibAppStorage.ds().auth, src, dst, sig);
        emit PermissionGranted(src, dst, sig);
    }

    function authorizeConfigurator(address _configurator) external authorised {
        if (_configurator == address(0) || !Address.isContract(_configurator)) {
            revert InvalidConfiguratorContract();
        }
        bytes4[] memory selectors = new bytes4[](16);
        selectors[0] = ILiquidityFacet(address(0)).initReserve.selector;
        selectors[1] = ILiquidityFacet(address(0)).activateReserve.selector;
        selectors[2] = ILiquidityFacet(address(0)).deactivateReserve.selector;
        selectors[3] = ILiquidityFacet(address(0)).updateProtocolFee.selector;
        selectors[4] = ILiquidityFacet(address(0)).updateWETH9.selector;

        selectors[5] = ILiquidityFacet(address(0))
            .upgradePriceOracleImpl
            .selector;
        selectors[6] = ConfigurationFacet(address(0))
            .setLiquidationBonus
            .selector;
        selectors[7] = ConfigurationFacet(address(0)).setIncomeRatio.selector;
        selectors[8] = ConfigurationFacet(address(0))
            .setOptimalLiquidityRatio
            .selector;
        selectors[9] = ConfigurationFacet(address(0))
            .setMaxTwapStaleness
            .selector;
        selectors[10] = ConfigurationFacet(address(0)).setLoanParams.selector;
        selectors[11] = ConfigurationFacet(address(0))
            .updateMarketPlaceData
            .selector;

        selectors[12] = ConfigurationFacet(address(0))
            .setGSNConfiguration
            .selector;
        selectors[13] = ConfigurationFacet(address(0))
            .upgradeJuniorDepositTokenImpl
            .selector;
        selectors[14] = ConfigurationFacet(address(0))
            .upgradeSeniorDepositTokenImpl
            .selector;
        selectors[15] = ConfigurationFacet(address(0))
            .setTwapTolerance
            .selector;

        LibSecurity.grantPermissions(
            LibAppStorage.ds().auth,
            _configurator,
            address(this),
            selectors
        );
    }

    function revokePermission(
        address src,
        address dst,
        bytes4 sig
    ) external authorised {
        LibSecurity.revokePermission(LibAppStorage.ds().auth, src, dst, sig);
        emit PermissionRevoked(src, dst, sig);
    }

    function isAuthorisedInbound(address src, bytes4 sig)
        external
        view
        returns (bool)
    {
        return
            LibSecurity.isAuthorisedInbound(LibAppStorage.ds().auth, src, sig);
    }

    function isAuthorisedOutbound(address dst, bytes4 sig)
        external
        view
        returns (bool)
    {
        return
            LibSecurity.isAuthorisedOutbound(LibAppStorage.ds().auth, dst, sig);
    }

    function isAuthorised(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool) {
        return LibSecurity.isAuthorised(LibAppStorage.ds().auth, src, dst, sig);
    }

    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool)
    {
        return LibSecurity.isTrustedForwarder(_forwarder);
    }

    function paused() external view returns (bool) {
        return LibAppStorage.ds()._paused;
    }
}

error InvalidConfiguratorContract();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LibAppStorage, AppStorage, RepayRecord, BorrowData, NFTInfo, DiamondFacet, ReserveConfigurationMap} from "./LibAppStorage.sol";
import {LibReserveConfiguration} from "./LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";

library LibVault {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using LibReserveConfiguration for ReserveConfigurationMap;

    function recordVault(address _owner, address _vault)
        internal
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.ds();
        require(s.vaultMap[_owner] == address(0), "one vault per owner");
        s.vaults.push(_vault);
        LibAppStorage.ds().vaultMap[_owner] = _vault;
        return (s.vaults.length);
    }

    function setVaultImpl(address _impl) internal {
        LibAppStorage.ds().vaultBeacon.upgradeTo(_impl);
    }

    /* ----------------------------- view functions ----------------------------- */
    function vaultBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.ds();
        return address(s.vaultBeacon);
    }

    function getVaultImpl() internal view returns (address) {
        return LibAppStorage.ds().vaultBeacon.implementation();
    }

    function subVaultBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.ds();
        return address(s.subVaultBeacon);
    }

    function getVaultAddress(address _owner) internal view returns (address) {
        return LibAppStorage.ds().vaultMap[_owner];
    }

    function getVaultDebt(
        address _collection,
        address _currency,
        address _vault
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.ds();
        BorrowData storage borrowData = s._borrowData[_collection][_currency][
            _vault
        ];
        return (borrowData.totalPrincipal, borrowData.totalInterest);
    }

    function getDiamondFacets() internal view returns (DiamondFacet memory) {
        AppStorage storage s = LibAppStorage.ds();
        return s.diamondFacet;
    }

    function slashRep(
        address _vault,
        address _collection,
        address _currency
    ) internal {
        AppStorage storage s = LibAppStorage.ds();
        s
        ._borrowState[_collection][_currency]
            .repayRecord[_vault]
            .defaultTimes += 1;
    }
}

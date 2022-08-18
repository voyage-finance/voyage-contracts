// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {LibAppStorage, AppStorage, BorrowData, NFTInfo, DiamondFacet, ReserveConfigurationMap} from "./LibAppStorage.sol";
import {LibReserveConfiguration} from "./LibReserveConfiguration.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {PercentageMath} from "../../shared/libraries/PercentageMath.sol";
import {LogarithmMath} from "../../shared/libraries/LogarithmMath.sol";

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

    function setVaultBeacon(address _impl) internal {
        AppStorage storage s = LibAppStorage.ds();
        s.vaultBeacon = new UpgradeableBeacon(_impl);
    }

    /* ----------------------------- view functions ----------------------------- */
    function vaultBeacon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.ds();
        return address(s.vaultBeacon);
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

    /**
     * @dev Get credit limit for a specific reserve
     * @param _vault vault address
     * @return _collection collection address
     **/
    function getCreditLimit(
        address _vault,
        address _collection,
        address _currency,
        uint256 _fv
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.ds();
        uint256 rep = s._borrowState[_collection][_currency].repaidTimes[
            _vault
        ];
        uint256 scaledRep = (rep + 1) * 1e18;
        uint256 multiplier = LogarithmMath.log2(scaledRep) + 1;
        return _fv * multiplier;
    }
}

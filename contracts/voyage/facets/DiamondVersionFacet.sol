// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Snapshot} from "../interfaces/IDiamondVersionFacet.sol";
import {AppStorage, Storage, LibAppStorage} from "../libraries/LibAppStorage.sol";
import {IDiamondLoupe} from "../../shared/diamond/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../../shared/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../shared/diamond/facets/DiamondCutFacet.sol";

contract DiamondVersionFacet is Storage {
    // increments `version` and stores snapshot in _snapshotMap
    // these must be computed offchain, and called by protocol admin (including init args encoding)
    function registerUpgrade(
        address init,
        bytes memory initArgs,
        IDiamondLoupe.Facet[] memory facets
    ) external authorised {
        LibAppStorage.diamondStorage().currentVersion += 1;
        uint256 version = LibAppStorage.diamondStorage().currentVersion;
        LibAppStorage.diamondStorage().snapshotMap[version].init = init;
        LibAppStorage.diamondStorage().snapshotMap[version].initArgs = initArgs;
        for (uint256 i = 0; i < facets.length; i++) {
            LibAppStorage.diamondStorage().snapshotMap[version].facets.push(
                facets[i]
            );
        }
    }

    function currentVersion() external view returns (uint256, bytes32) {
        uint256 version = LibAppStorage.diamondStorage().currentVersion;
        Snapshot memory snapshot = LibAppStorage.diamondStorage().snapshotMap[
            version
        ];
        return (version, computeSnapshotChecksum(snapshot));
    }

    function isUpToDate(uint256 _version) external view returns (bool) {
        return _version == LibAppStorage.diamondStorage().currentVersion;
    }

    function computeSnapshotChecksum(Snapshot memory snapshot)
        internal
        view
        returns (bytes32)
    {
        bytes memory data;
        for (uint256 i = 0; i < snapshot.facets.length; i++) {
            IDiamondLoupe.Facet memory facet = snapshot.facets[i];
            data = bytes.concat(data, abi.encodePacked(facet.facetAddress));
            for (uint256 j = 0; j < facet.functionSelectors.length; j++) {
                data = bytes.concat(data, facet.functionSelectors[j]);
            }
            bytes32 facetCodeHash;
            address facetAddress = facet.facetAddress;
            assembly {
                facetCodeHash := extcodehash(facetAddress)
            }
            data = bytes.concat(data, facetCodeHash);
        }
        return keccak256(data);
    }
}

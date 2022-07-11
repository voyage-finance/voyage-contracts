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
    ) public authorised {
        LibAppStorage.diamondStorage().currentVersion += 1;
        uint256 version = LibAppStorage.diamondStorage().currentVersion;
        LibAppStorage.diamondStorage().snapshotMap[version].init = init;
        LibAppStorage.diamondStorage().snapshotMap[version].initArgs = initArgs;
        for (uint256 i = 0; i < facets.length; ) {
            LibAppStorage.diamondStorage().snapshotMap[version].facets.push(
                facets[i]
            );
            unchecked {
                i++;
            }
        }
    }

    function getUpgrade(address _vault)
        public
        returns (IDiamondCut.FacetCut[] memory)
    {
        IDiamondCut.FacetCut[] storage facetCuts = s.upgradeParam.facetCuts[
            msg.sender
        ];
        Snapshot memory snapshot = s.snapshotMap[s.currentVersion];
        IDiamondLoupe loupe = IDiamondLoupe(_vault);
        IDiamondLoupe.Facet[] memory currentFacets = loupe.facets();

        mapping(bytes4 => address) storage existingSelectorFacetMap = s
            .upgradeParam
            .existingSelectorFacetMap[msg.sender];
        bytes4[] storage existingSelectors = s.upgradeParam.existingSelectors[
            msg.sender
        ];

        mapping(bytes4 => bool) storage newSelectorSet = s
            .upgradeParam
            .newSelectorSet[msg.sender];
        bytes4[] storage newSelectors = s.upgradeParam.newSelectors[msg.sender];

        for (uint256 i = 0; i < currentFacets.length; ) {
            IDiamondLoupe.Facet memory facet = currentFacets[i];
            for (uint256 j = 0; j < facet.functionSelectors.length; ) {
                bytes4 selector = facet.functionSelectors[j];
                newSelectors.push(selector);
                existingSelectorFacetMap[selector] = facet.facetAddress;
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        // at this point, we have to compute which facets to add/replace/delete
        // the logic is identical to the deployment script in voyager_001.ts
        // first, compute the selectors to add or replace
        for (uint256 i = 0; i < snapshot.facets.length; ) {
            IDiamondLoupe.Facet memory candidateFacet = snapshot.facets[i];
            for (uint256 j = 0; j < candidateFacet.functionSelectors.length; ) {
                bytes4 selector = candidateFacet.functionSelectors[j];
                // add it to newSelectorSet
                newSelectorSet[selector] = true;
                address currentHostFacetAddress = existingSelectorFacetMap[
                    selector
                ];
                if (currentHostFacetAddress != address(0)) {
                    if (
                        currentHostFacetAddress != candidateFacet.facetAddress
                    ) {
                        s.upgradeParam.selectorsReplaced[i].push(selector);
                    }
                } else {
                    s.upgradeParam.selectorsAdded[i].push(selector);
                }
                unchecked {
                    ++j;
                }
            }

            if (s.upgradeParam.selectorsAdded[i].length > 0) {
                IDiamondCut.FacetCut memory facetCut;
                facetCut.functionSelectors = s.upgradeParam.selectorsAdded[i];
                facetCut.facetAddress = candidateFacet.facetAddress;
                facetCut.action = IDiamondCut.FacetCutAction.Add;

                facetCuts[s.upgradeParam.facetCutSize[msg.sender]] = facetCut;
                s.upgradeParam.facetCutSize[msg.sender]++;

                // clean storage right away
                delete s.upgradeParam.selectorsAdded[i];
            }

            if (s.upgradeParam.selectorsReplaced[i].length > 0) {
                IDiamondCut.FacetCut memory facetCut;
                facetCut.functionSelectors = s.upgradeParam.selectorsReplaced[
                    i
                ];
                facetCut.facetAddress = candidateFacet.facetAddress;
                facetCut.action = IDiamondCut.FacetCutAction.Replace;

                facetCuts[s.upgradeParam.facetCutSize[msg.sender]] = facetCut;
                s.upgradeParam.facetCutSize[msg.sender]++;

                // clean storage right away
                delete s.upgradeParam.selectorsReplaced[i];
            }
            unchecked {
                ++i;
            }
        }

        // now just get the XOR of existing and new selectors to find the removed set
        for (uint256 i = 0; i < existingSelectors.length; ) {
            if (!newSelectorSet[existingSelectors[i]]) {
                s.upgradeParam.selectorsRemoved[i].push(existingSelectors[i]);
            }

            if (s.upgradeParam.selectorsRemoved[i].length > 0) {
                IDiamondCut.FacetCut memory facetCut;
                facetCut.functionSelectors = s.upgradeParam.selectorsRemoved[i];
                facetCut.facetAddress = address(0);
                facetCut.action = IDiamondCut.FacetCutAction.Remove;

                facetCuts[s.upgradeParam.facetCutSize[msg.sender]] = facetCut;
                s.upgradeParam.facetCutSize[msg.sender]++;

                // clean storage right away
                delete s.upgradeParam.selectorsRemoved[i];
            }

            unchecked {
                ++i;
            }
        }

        IDiamondCut.FacetCut[] memory ret = new IDiamondCut.FacetCut[](
            s.upgradeParam.facetCutSize[msg.sender]
        );
        for (uint256 i = 0; i < s.upgradeParam.facetCutSize[msg.sender]; ) {
            ret[i] = facetCuts[i];
            unchecked {
                ++i;
            }
        }

        LibAppStorage.cleanUpgradeParam();

        return ret;
    }

    function currentVersion() public view returns (uint256, bytes32) {
        uint256 version = LibAppStorage.diamondStorage().currentVersion;
        Snapshot memory snapshot = LibAppStorage.diamondStorage().snapshotMap[
            version
        ];
        return (version, computeSnapshotChecksum(snapshot));
    }

    function isUpToDate(uint256 _version) public view returns (bool) {
        return _version == LibAppStorage.diamondStorage().currentVersion;
    }
}

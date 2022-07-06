// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondLoupe} from "../../shared/diamond/interfaces/IDiamondLoupe.sol";

struct Snapshot {
    IDiamondLoupe.Facet[] facets;
    address init; // address of InitDiamondVx
    bytes initArgs; // abi encoded args to pass to InitDiamondVX
}

interface IDiamondVersionFacet {
    // clone should create a fresh Vault with the facets recorded in `Snapshot` of current version
    function clone() external returns (address);

    // increments `version` and stores snapshot in _snapshotMap
    // these must be computed offchain, and called by protocol admin (including init args encoding)
    function registerUpgrade(Snapshot memory _snapshot) external;

    // return version number and snapshot hash
    function currentVersion() external view returns (uint256, bytes32);

    function isUpToDate(uint256 _version) external view returns (bool);

    // returns the current snapshot
    function getSnapshot() external view returns (Snapshot memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VersionedDiamond} from "../shared/diamond/VersionedDiamond.sol";
import {LibVaultStorage} from "./libraries/LibVaultStorage.sol";
import "hardhat/console.sol";

contract Vault is VersionedDiamond {
    constructor(
        address _owner,
        address _voyage,
        uint256 _version,
        bytes32 _checksum
    ) VersionedDiamond(_voyage) {
        LibVaultStorage.diamondStorage().voyage = _voyage;
        LibVaultStorage.diamondStorage().owner = _owner;
        LibVaultStorage.diamondStorage().version = _version;
        LibVaultStorage.diamondStorage().checksum = _checksum;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VersionedDiamond} from "../shared/diamond/VersionedDiamond.sol";
import {LibVaultStorage} from "./libraries/LibVaultStorage.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVault} from "./interfaces/IVault.sol";
import "hardhat/console.sol";

contract Vault is VersionedDiamond, IVault {
    function initialize(
        address _owner,
        address _voyage,
        address _cutFacet,
        address _loupeFacet,
        address _ownershipFacet
    ) public initializer {
        LibVaultStorage.diamondStorage().voyage = _voyage;
        LibVaultStorage.diamondStorage().owner = _owner;
        _initialize(_owner, _cutFacet, _loupeFacet, _ownershipFacet);
    }
}

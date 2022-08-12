// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VersionedDiamond} from "../shared/diamond/VersionedDiamond.sol";
import {LibVaultStorage} from "./libraries/LibVaultStorage.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVault} from "./interfaces/IVault.sol";

contract Vault is VersionedDiamond, IVault {
    function initialize(
        address _owner,
        address _user,
        address _paymaster,
        address _weth9,
        address _cutFacet,
        address _loupeFacet,
        address _ownershipFacet
    ) public initializer {
        LibVaultStorage.ds().voyage = _owner;
        LibVaultStorage.ds().user = _user;
        LibVaultStorage.ds().paymaster = _paymaster;
        LibVaultStorage.ds().weth9 = _weth9;
        _initialize(_owner, _cutFacet, _loupeFacet, _ownershipFacet);
    }
}

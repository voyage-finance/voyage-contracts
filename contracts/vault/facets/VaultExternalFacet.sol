// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {CustodyData, VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {Call} from "../interfaces/ICallExternal.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";

contract VaultExternalFacet is Storage {
    function callExternal(address target, bytes calldata data)
        external
        onlyVoyage
        returns (bytes memory)
    {
        (bool success, bytes memory ret) = target.call(data);
        require(success);
        return ret;
    }
}

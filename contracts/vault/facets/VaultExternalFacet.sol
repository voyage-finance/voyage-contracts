// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {CustodyData, VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {Call} from "../interfaces/ICallExternal.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";

contract VaultExternalFacet is Storage {
    /// @notice To accept external calls from authorised client, used for pursing NFT or doing approve etc.
    function callExternal(Call[] calldata calls)
        external
        returns (bytes[] memory)
    {
        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            returnData[i] = callExternal(calls[i].target, calls[i].callData);
        }
        return returnData;
    }

    function callExternal(address target, bytes calldata data)
        internal
        returns (bytes memory)
    {
        VaultFacet vf = VaultFacet(LibVaultStorage.diamondStorage().voyage);
        bytes4 selector = bytes4(data[0:4]);
        bytes memory args = data[4:];
        (
            address[] memory beforeTarget,
            bytes[] memory beforeData,
            address[] memory onSuccessTarget,
            bytes[] memory onSuccessData
        ) = vf.validate(target, selector, args);
        _call(beforeTarget, beforeData);
        (bool success, bytes memory ret) = target.call(data);
        require(success);
        _call(onSuccessTarget, onSuccessData);
        return ret;
    }

    function _call(address[] memory target, bytes[] memory data) internal {
        for (uint256 i = 0; i < target.length; i++) {
            if (target[i] != address(0)) {
                (bool success, bytes memory ret) = target[i].call(data[i]);
                require(success, "invalid before call");
            }
        }
    }
}

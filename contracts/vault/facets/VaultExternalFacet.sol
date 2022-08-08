// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VaultAuth} from "../libraries/LibAuth.sol";

contract VaultExternalFacet is VaultAuth {
    function exec(bytes calldata _data) public authorised {
        (address target, bytes memory data) = abi.decode(
            _data,
            (address, bytes)
        );
        (bool success, bytes memory ret) = target.call(data);
        if (!success) {
            revert InvalidCall();
        }
    }

    error InvalidCall();
}

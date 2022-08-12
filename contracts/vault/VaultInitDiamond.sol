// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {LibVaultStorage, VaultStorageV1} from "./libraries/LibVaultStorage.sol";

contract VaultInitDiamond {
    struct Args {
        address paymaster;
    }

    function init(Args memory _args) external {
        VaultStorageV1 storage vs = LibVaultStorage.ds();
        if (vs.paymaster == address(0)) {
            vs.paymaster = _args.paymaster;
        }
    }
}

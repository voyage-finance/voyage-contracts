// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Vault} from "./Vault.sol";
import {IVaultFactory} from "../../interfaces/IVaultFactory.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract VaultFactory is IVaultFactory {
    function createVault(bytes32 salt) external returns (address) {
        return Create2.deploy(0, salt, type(Vault).creationCode);
    }
}

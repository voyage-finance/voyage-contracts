// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/utils/Create2.sol";
import {Vault} from "../vault/Vault.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";

contract VaultFactory is IVaultFactory {
    function createVault(
        address owner,
        address voyage,
        bytes32 salt
    ) external returns (address) {
        bytes memory creationCode = type(Vault).creationCode;

        bytes memory bytecode = abi.encodePacked(
            creationCode,
            abi.encode(owner, voyage)
        );

        return Create2.deploy(0, salt, bytecode);
    }
}

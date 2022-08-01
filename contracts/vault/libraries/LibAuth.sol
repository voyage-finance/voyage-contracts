// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {SecurityFacet} from "../../voyage/facets/SecurityFacet.sol";
import {LibVaultStorage} from "./LibVaultStorage.sol";

contract VaultAuth {
    modifier authorised() {
        SecurityFacet sf = SecurityFacet(LibVaultStorage.ds().voyage);
        require(
            sf.isAuthorised(msg.sender, address(this), msg.sig),
            "unauthorised"
        );
        _;
    }
}

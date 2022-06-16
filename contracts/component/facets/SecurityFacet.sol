// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Storage} from "../../libraries/LibAppStorage.sol";

contract SecurityFacet is Storage {
    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool) {
        return s._paused;
    }

    function pause() public onlyAdmin {
        s._paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyAdmin {
        s._paused = false;
        emit Unpaused(_msgSender());
    }
}

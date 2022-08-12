// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import {Storage, LibAppStorage} from "../voyage/libraries/LibAppStorage.sol";

contract MockContextFacet is Storage {
    event Sender(address sender);

    function msgSender() public {
        emit Sender(_msgSender());
    }

    event Data(bytes data, uint256 integerValue, string stringValue);

    function msgData(uint256 integerValue, string memory stringValue) public {
        emit Data(_msgData(), integerValue, stringValue);
    }
}

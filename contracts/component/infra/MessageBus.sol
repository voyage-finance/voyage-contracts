// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AddressResolver} from "./AddressResolver.sol";
import {IMessageBus} from "../../interfaces/IMessageBus.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Storage, ADDRESS_RESOLVER} from "../../libraries/LibAppStorage.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * todo it might be a bad name here, it actually performs as the centralise place
 * for querying each other among the internal components
 **/
contract MessageBus is Storage {
    /**
     * @dev Get addressResolver contract address
     * @return address of the resolver contract
     **/
    function addressResolver() external view returns (AddressResolver) {
        return AddressResolver(_addressResolver());
    }
}

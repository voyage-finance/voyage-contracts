// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {BasicOrderType, AdditionalRecipient, BasicOrderParameters} from "../voyage/adapter/SeaportAdapter.sol";
import "hardhat/console.sol";

contract MockSeaport {
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled)
    {
        console.log("MockSeaport#fulfillBasicOrder");
    }
}

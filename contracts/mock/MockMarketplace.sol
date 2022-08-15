// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {TakerOrder, MakerOrder} from "../voyage/adapter/LooksRareAdapter.sol";
import "hardhat/console.sol";

contract MockMarketPlace {
    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external {
        console.log("in matchAskWithTakerBid");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {TakerOrder, MakerOrder} from "../voyage/adapter/LooksRareAdapter.sol";
import "hardhat/console.sol";

contract MockMarketPlace {
    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable {
        console.log("in matchAskWithTakerBidUsingETHAndWETH");
        logTakerOrder(takerBid);
        logMakerOrder(makerAsk);
    }

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable {
        console.log("in matchAskWithTakerBid");
        logTakerOrder(takerBid);
        logMakerOrder(makerAsk);
    }

    function logTakerOrder(TakerOrder calldata takerBid) internal {
        console.log("TakerOrder.isOrderAsk: ", takerBid.isOrderAsk);
        console.log("TakerOrder.taker: ", takerBid.taker);
        console.log("TakerOrder.price: ", takerBid.price);
        console.log("TakerOrder.tokenId: ", takerBid.tokenId);
        console.log(
            "TakerOrder.minPercentageToAsk: ",
            takerBid.minPercentageToAsk
        );
        console.log("TakerOrder.params:");
        console.logBytes(takerBid.params);
    }

    function logMakerOrder(MakerOrder calldata makerAsk) internal {
        console.log("MakerOrder.isOrderAsk: ", makerAsk.isOrderAsk);
        console.log("MakerOrder.signer: ", makerAsk.signer);
        console.log("MakerOrder.collection: ", makerAsk.collection);
        console.log("MakerOrder.price: ", makerAsk.price);
        console.log("MakerOrder.tokenId: ", makerAsk.tokenId);
        console.log("MakerOrder.amount: ", makerAsk.amount);
        console.log("MakerOrder.strategy: ", makerAsk.strategy);
        console.log("MakerOrder.currency: ", makerAsk.currency);
        console.log("MakerOrder.nonce: ", makerAsk.nonce);
        console.log("MakerOrder.startTime: ", makerAsk.startTime);
        console.log("MakerOrder.endTime: ", makerAsk.endTime);
        console.log(
            "MakerOrder.minPercentageToAsk: ",
            makerAsk.minPercentageToAsk
        );
        console.log("MakerOrder.params: ");
        console.logBytes("MakerOrder.params: ");
        console.log("MakerOrder.v: ", makerAsk.v);
        console.logBytes32(makerAsk.r);
        console.logBytes32(makerAsk.s);
    }
}

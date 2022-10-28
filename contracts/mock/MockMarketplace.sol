// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {TakerOrder, MakerOrder} from "../voyage/adapter/LooksRareAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

contract MockMarketPlace {
    using SafeERC20 for IERC20;

    address weth;

    constructor(address _weth) {
        weth = _weth;
    }

    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable {
        // console.log("in matchAskWithTakerBidUsingETHAndWETH");
        logTakerOrder(takerBid);
        logMakerOrder(makerAsk);
        safeTransferFrom(makerAsk.currency, msg.sender, makerAsk.price);
    }

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable {
        console.log("in matchAskWithTakerBid");
        console.log("value: %s", msg.value);
        logTakerOrder(takerBid);
        logMakerOrder(makerAsk);
        safeTransferFrom(makerAsk.currency, msg.sender, makerAsk.price);
    }

    function logTakerOrder(TakerOrder calldata takerBid) internal view {
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

    function safeTransferFrom(
        address currency,
        address payer,
        uint256 value
    ) internal {
        if (currency != 0x0000000000000000000000000000000000000000) {
            IERC20(weth).safeTransferFrom(payer, address(this), value);
        }
    }

    function logMakerOrder(MakerOrder calldata makerAsk) internal view {
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

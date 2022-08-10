// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IMarketPlaceAdapter} from "../interfaces/IMarketPlaceAdapter.sol";

struct MakerOrder {
    bool isOrderAsk; // true --> ask / false --> bid
    address signer; // signer of the maker order
    address collection; // collection address
    uint256 price; // price (used as )
    uint256 tokenId; // id of the token
    uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
    address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
    address currency; // currency (e.g., WETH)
    uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
    uint256 startTime; // startTime in timestamp
    uint256 endTime; // endTime in timestamp
    uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
    bytes params; // additional parameters
    uint8 v; // v: parameter (27 or 28)
    bytes32 r; // r: parameter
    bytes32 s; // s: parameter
}

struct TakerOrder {
    bool isOrderAsk; // true --> ask / false --> bid
    address taker; // msg.sender
    uint256 price; // final price for the purchase
    uint256 tokenId;
    uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
    bytes params; // other params (e.g., tokenId)
}

interface ILooksRareExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external;

    function matchBidWithTakerAsk(
        TakerOrder calldata takerAsk,
        MakerOrder calldata makerBid
    ) external;
}

contract LooksRareAdapter is IMarketPlaceAdapter {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH =
        0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    function hash(MakerOrder memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }

    struct PurchaseParam {
        address marketplace;
        bytes4 selector;
        bytes makerOrder;
        bytes takerOrder;
    }

    function extractAssetPrice(bytes calldata _data)
        external
        pure
        returns (uint256)
    {
        PurchaseParam memory param;
        (
            param.marketplace,
            param.selector,
            param.makerOrder,
            param.takerOrder
        ) = abi.decode(_data, (address, bytes4, bytes, bytes));

        TakerOrder memory takerOrder;
        (
            takerOrder.isOrderAsk,
            takerOrder.taker,
            takerOrder.price,
            takerOrder.tokenId,
            takerOrder.minPercentageToAsk,
            takerOrder.params
        ) = abi.decode(
            param.takerOrder,
            (bool, address, uint256, uint256, uint256, bytes)
        );

        return takerOrder.price;
    }

    function validate(bytes calldata _data) external pure returns (bool) {
        return _validate(_data);
    }

    function execute(bytes calldata _data)
        external
        pure
        returns (bytes memory)
    {
        if (_validate(_data)) {
            PurchaseParam memory param;
            (
                param.marketplace,
                param.selector,
                param.makerOrder,
                param.takerOrder
            ) = abi.decode(_data, (address, bytes4, bytes, bytes));
            bytes memory data = abi.encode(param.takerOrder, param.makerOrder);
            data = abi.encodePacked(param.selector, data);
            return data;
        }
        // use native error type here cause an ABI issue
        revert("invalid data");
    }

    function _validate(bytes calldata _data) private pure returns (bool) {
        PurchaseParam memory param;
        (
            param.marketplace,
            param.selector,
            param.makerOrder,
            param.takerOrder
        ) = abi.decode(_data, (address, bytes4, bytes, bytes));

        // bytes4(keccak256(matchAskWithTakerBidUsingETHAndWETH()))
        // 0xb4e4b296
        if (
            param.selector !=
            ILooksRareExchange(address(0))
                .matchAskWithTakerBidUsingETHAndWETH
                .selector
        ) {
            return false;
        }
        return true;
    }
}
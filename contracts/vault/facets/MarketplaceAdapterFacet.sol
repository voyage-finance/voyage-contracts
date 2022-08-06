// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {VaultAuth} from "../libraries/LibAuth.sol";
import {ILooksRareExchange} from "../../shared/interfaces/ILooksRareExchange.sol";
import {OrderTypes} from "../../shared/libraries/OrderTypes.sol";
import "hardhat/console.sol";

contract MarketplaceAdapterFacet is VaultAuth {
    struct PurchaseParam {
        address marketplace;
        bytes4 selector;
        bytes makerOrder;
        bytes takerOrder;
    }

    function extractAssetPrice(bytes calldata _data)
        public
        view
        returns (uint256)
    {
        PurchaseParam memory param;
        (
            param.marketplace,
            param.selector,
            param.makerOrder,
            param.takerOrder
        ) = abi.decode(_data, (address, bytes4, bytes, bytes));

        OrderTypes.TakerOrder memory takerOrder;
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

    function validate(bytes calldata _data) public view returns (bool) {
        PurchaseParam memory param;
        (
            param.marketplace,
            param.selector,
            param.makerOrder,
            param.takerOrder
        ) = abi.decode(_data, (address, bytes4, bytes, bytes));
        if (param.marketplace == address(0)) {
            revert InvalidMakerplace();
        }
        if (
            param.selector !=
            ILooksRareExchange(address(0))
                .matchAskWithTakerBidUsingETHAndWETH
                .selector
        ) {
            revert InvalidSelector();
        }
        OrderTypes.TakerOrder memory takerOrder;
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
        if (takerOrder.taker != address(this)) {
            revert InvalidTaker();
        }

        return true;
    }

    function purchase(bytes calldata _data) public authorised {
        validate(_data);
        PurchaseParam memory param;
        (
            param.marketplace,
            param.selector,
            param.makerOrder,
            param.takerOrder
        ) = abi.decode(_data, (address, bytes4, bytes, bytes));
        bytes memory data = abi.encode(param.takerOrder, param.makerOrder);
        data = abi.encodePacked(param.selector, data);
        (bool success, bytes memory ret) = param.marketplace.call(data);
        if (!success) {
            revert InvalidCall();
        }
    }

    error InvalidMakerplace();
    error InvalidSelector();
    error InvalidCall();
    error InvalidTaker();
}

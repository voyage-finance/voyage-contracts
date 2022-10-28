// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {BasicOrderType, AdditionalRecipient, BasicOrderParameters} from "../voyage/adapter/SeaportAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

contract MockSeaport {
    using SafeERC20 for IERC20;

    address weth;

    constructor(address _weth) {
        weth = _weth;
    }

    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool)
    {
        console.log("MockSeaport#fulfillBasicOrder");
        logParameters(parameters);
        safeTransferFrom(
            parameters.considerationToken,
            msg.sender,
            parameters.considerationAmount
        );
    }

    function logParameters(BasicOrderParameters calldata parameters)
        internal
        view
    {
        console.log(
            "BasicOrderParameters.considerationToken: ",
            parameters.considerationToken
        );
        console.log(
            "BasicOrderParameters.considerationIdentifier: ",
            parameters.considerationIdentifier
        );
        console.log(
            "BasicOrderParameters.considerationAmount: ",
            parameters.considerationAmount
        );
        console.log("BasicOrderParameters.offerer: ", parameters.offerer);
        console.log("BasicOrderParameters.zone: ", parameters.zone);
        console.log("BasicOrderParameters.offerToken: ", parameters.offerToken);
        console.log(
            "BasicOrderParameters.offerIdentifier: ",
            parameters.offerIdentifier
        );
        console.log(
            "BasicOrderParameters.offerAmount: ",
            parameters.offerAmount
        );
        console.log("BasicOrderParameters.startTime: ", parameters.startTime);
        console.log("BasicOrderParameters.endTime: ", parameters.endTime);
        console.logBytes32(parameters.zoneHash);
        console.log("BasicOrderParameters.salt: ", parameters.salt);
        console.logBytes32(parameters.offererConduitKey);
        console.logBytes32(parameters.fulfillerConduitKey);
        console.log(
            "BasicOrderParameters.totalOriginalAdditionalRecipients: ",
            parameters.totalOriginalAdditionalRecipients
        );
        console.log("params.signature: ");
        console.logBytes(parameters.signature);
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
}

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
        logParameters(parameters);
    }

    function logParameters(BasicOrderParameters calldata parameters) internal {
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
}

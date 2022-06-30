// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IERC721Token} from "./IERC721Token.sol";
import "hardhat/console.sol";

contract MockCrabadaBattleGame {
    function depositNFT721(
        IERC721Token token,
        address to,
        uint256[] calldata ids
    ) public {
        console.log("MockCrabadaBattleGame#depositNFT721 to: ", to);
    }

    function withdrawNFT721(
        IERC721Token token,
        uint256[] calldata ids,
        uint256 expiredTime,
        uint256 nonce,
        bytes calldata signature
    ) public {
        console.log("MockCrabadaBattleGame#withdrawNFT721 nonce: ", nonce);
    }
}

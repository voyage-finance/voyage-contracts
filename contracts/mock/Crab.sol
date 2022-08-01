// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Token} from "./IERC721Token.sol";

contract Crab is ERC721, IERC721Token {
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function safeMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal override {
        _transfer(from, to, tokenId);
        IERC721Receiver(to).onERC721Received(to, from, tokenId, _data);
    }
}

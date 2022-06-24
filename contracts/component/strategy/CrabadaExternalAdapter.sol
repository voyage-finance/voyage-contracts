// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IExternalAdapter} from "../../interfaces/IExternalAdapter.sol";
import {VaultFacet} from "../facets/VaultFacet.sol";

contract CrabadaExternalAdapter is IExternalAdapter {
    address immutable erc721Addr;
    address immutable erc20Addr;
    address immutable marketPlace;
    address immutable voyager;

    constructor(
        address _voyager,
        address _erc721Addr,
        address _erc20Addr,
        address _marketPlace
    ) {
        voyager = _voyager;
        erc721Addr = _erc721Addr;
        erc20Addr = _erc20Addr;
        marketPlace = _marketPlace;
    }

    function getERC721() external returns (address) {
        return erc721Addr;
    }

    function validate(
        address target,
        bytes4 selector,
        bytes calldata payload
    ) external returns (address onSuccessTarget, bytes memory onSuccessData) {
        if (validateMarketplaceFunc(target, selector, payload)) {
            uint256 orderId = abi.decode(payload, (uint256));
            (bool success, bytes memory returnedData) = marketPlace.call(
                abi.encodeWithSignature("sellOrders(uint256)", orderId)
            );
            (address owner, uint256 cardId, uint256 cardPrice) = abi.decode(
                returnedData,
                (address, uint256, uint256)
            );
            onSuccessData = abi.encodeWithSignature(
                "updateNFTPrice(address,uint256,uint256)",
                erc721Addr,
                cardId,
                cardPrice
            );
            return (voyager, onSuccessData);
        }

        if (validateERC20Func(target, selector, payload)) {
            return (address(0), abi.encodeWithSignature(""));
        }
        revert("CrabadaExternalAdapter: invalid call");
    }

    function validateERC20Func(
        address target,
        bytes4 selector,
        bytes calldata payload
    ) internal view returns (bool) {
        (address spender, uint256 addAmount) = abi.decode(
            payload,
            (address, uint256)
        );
        if (
            target == erc20Addr &&
            bytes4(keccak256("approve(address,uint256)")) == selector &&
            spender != address(0) &&
            addAmount != 0
        ) {
            return true;
        }
        return false;
    }

    function validateMarketplaceFunc(
        address target,
        bytes4 selector,
        bytes calldata payload
    ) internal returns (bool) {
        if (
            target == marketPlace &&
            bytes4(keccak256("buyCard(uint256)")) == selector
        ) {
            return true;
        }

        return false;
    }
}

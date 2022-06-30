// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IExternalAdapter} from "../../interfaces/IExternalAdapter.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {VaultFacet} from "../facets/VaultFacet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrabadaExternalAdapter is IExternalAdapter {
    using SafeMath for uint256;

    address immutable erc721Addr;
    address immutable erc20Addr;
    address immutable marketPlace;
    address immutable battleGame;
    address immutable voyager;

    constructor(
        address _voyager,
        address _erc721Addr,
        address _erc20Addr,
        address _marketPlace,
        address _battleGame
    ) {
        voyager = _voyager;
        erc721Addr = _erc721Addr;
        erc20Addr = _erc20Addr;
        marketPlace = _marketPlace;
        battleGame = _battleGame;
    }

    function getERC721() external returns (address) {
        return erc721Addr;
    }

    struct ValidationParam {
        address vault;
        address target;
        bytes4 selector;
    }

    function validate(
        address vault,
        address target,
        bytes4 selector,
        bytes calldata payload
    )
        external
        returns (
            address[] memory beforeTarget,
            bytes[] memory beforeData,
            address[] memory onSuccessTarget,
            bytes[] memory onSuccessData
        )
    {
        ValidationParam memory param;
        param.vault = vault;
        param.target = target;
        param.selector = selector;
        if (validateMarketplaceFunc(param.target, param.selector, payload)) {
            uint256 orderId = abi.decode(payload, (uint256));
            (bool success, bytes memory returnedData) = marketPlace.call(
                abi.encodeWithSignature("sellOrders(uint256)", orderId)
            );
            (address owner, uint256 cardId, uint256 cardPrice) = abi.decode(
                returnedData,
                (address, uint256, uint256)
            );
            onSuccessTarget = new address[](2);
            onSuccessData = new bytes[](2);
            onSuccessTarget[0] = voyager;
            onSuccessData[0] = abi.encodeWithSignature(
                "updateNFTPrice(address,uint256,uint256)",
                erc721Addr,
                cardId,
                cardPrice
            );
            onSuccessTarget[1] = param.vault;
            onSuccessData[1] = abi.encodeWithSignature(
                "refund(address,address,uint256)",
                erc721Addr,
                erc20Addr,
                IERC20(erc20Addr).balanceOf(param.vault)
            );
            beforeTarget = new address[](1);
            beforeData = new bytes[](1);
            beforeTarget[0] = IVault(param.vault).creditEscrow(erc20Addr);
            beforeData[0] = abi.encodeWithSignature(
                "transferUnderlyingTo(address,address,uint256)",
                erc20Addr,
                param.vault,
                cardPrice.mul(2)
            );
            return (beforeTarget, beforeData, onSuccessTarget, onSuccessData);
        }

        if (
            validateERC20Func(param.target, param.selector, payload) ||
            validateBattle(param.target, param.selector, payload)
        ) {
            return (beforeTarget, beforeData, onSuccessTarget, onSuccessData);
        }

        revert("CrabadaExternalAdapter: invalid call");
    }

    function validateBattle(
        address target,
        bytes4 selector,
        bytes calldata payload
    ) internal view returns (bool) {
        if (target != battleGame) {
            return false;
        }
        // depositNFT721(IERC721Token token, address to, uint256[] calldata ids)
        if (
            bytes4(keccak256("depositNFT721(address,address,uint256[])")) ==
            selector
        ) {
            (address token, address to, uint256[] memory ids) = abi.decode(
                payload,
                (address, address, uint256[])
            );
            if (token == address(0) || to == address(0) || ids.length == 0) {
                return false;
            }
            return true;
        }

        // withdrawNFT721(IERC721Token token, uint256[] calldata ids, uint256 expiredTime, uint256 nonce, bytes calldata signature)
        if (
            bytes4(
                keccak256(
                    "withdrawNFT721(address,uint256[],uint256,uint256,bytes)"
                )
            ) == selector
        ) {
            (
                address token,
                uint256[] memory ids,
                uint256 expiredTime,
                uint256 nonce,
                bytes memory signature
            ) = abi.decode(
                    payload,
                    (address, uint256[], uint256, uint256, bytes)
                );

            if (token == address(0) || ids.length == 0 || expiredTime == 0) {
                return false;
            }

            return true;
        }

        return false;
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

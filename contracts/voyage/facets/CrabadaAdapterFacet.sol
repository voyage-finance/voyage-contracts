// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {AppStorage, Storage} from "../libraries/LibAppStorage.sol";
import {LibVault} from "../libraries/LibVault.sol";
import {LibLiquidity} from "../libraries/LibLiquidity.sol";
import {Call} from "../../vault/interfaces/ICallExternal.sol";
import {WadRayMath} from "../../shared/libraries/WadRayMath.sol";
import {VaultDataFacet} from "../../vault/facets/VaultDataFacet.sol";
import {VaultAssetFacet} from "../../vault/facets/VaultAssetFacet.sol";
import {VaultExternalFacet} from "../../vault/facets/VaultExternalFacet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CrabadaAdapterFacet is Storage, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    struct ExecuteBuyParam {
        address nftAddr;
        address erc20Addr;
        address marketplace;
        address vault;
        uint256 orderId;
        address seller;
        uint256 tokenId;
        uint256 tokenPrice;
    }

    event Order(
        address indexed nftAddr,
        address buyer,
        address seller,
        uint256 tokenId,
        uint256 tokenPrice
    );

    /// target.0 should be erc20 contract address
    /// target.1 should be marketplace contract
    function approveBuy(
        address _nftAddr,
        uint256 _orderId,
        address _vault
    ) public nonReentrant {
        address erc20 = LibVault.getERC20ByAsset(_nftAddr);
        address marketplace = LibVault.getMarketPlaceByAsset(_nftAddr);
        if (IERC20(erc20).allowance(_vault, marketplace) != type(uint256).max) {
            approve(erc20, marketplace, type(uint256).max, _vault);
        }
        buy(_nftAddr, erc20, marketplace, _orderId, _vault);
    }

    /// depositNFT721(address,address,uint256[])
    /// depositNFT721(IERC721Token token, address to, uint256[] calldata ids)
    function depositToBattleGame(
        address _vault,
        address _marketplace,
        address _tokenAddr,
        address to,
        uint256[] calldata ids
    ) public nonReentrant {
        _auth(_vault);
        bytes memory callData = abi.encodeWithSignature(
            "depositNFT721(address,address,uint256)",
            _tokenAddr,
            to,
            ids
        );
        _call(_vault, _marketplace, callData);
    }

    /// withdrawNFT721(address,uint256[],uint256,uint256,bytes)
    /// withdrawNFT721(IERC721Token token, uint256[] calldata ids, uint256 expiredTime, uint256 nonce, bytes calldata signature)
    function withdrawFromBattleGame(
        address _vault,
        address _marketplace,
        address _tokenAddr,
        uint256[] calldata ids,
        uint256 expiredTime,
        uint256 nonce,
        bytes calldata signature
    ) public nonReentrant {
        _auth(_vault);
        bytes memory callData = abi.encodeWithSignature(
            "withdrawNFT721(address,uint256[],uint256,uint256,bytes)",
            _tokenAddr,
            ids,
            expiredTime,
            nonce,
            signature
        );
        _call(_vault, _marketplace, callData);
    }

    /// approve(address,uint256)
    function approve(
        address _target,
        address _spender,
        uint256 _amount,
        address _vault
    ) internal {
        _auth(_vault);
        bytes memory callData = abi.encodeWithSignature(
            "approve(address,uint256)",
            _spender,
            _amount
        );
        _call(_vault, _target, callData);
    }

    /// buyCard(uint256)
    function buy(
        address _nftAddr,
        address _erc20,
        address _marketplace,
        uint256 _orderId,
        address _vault
    ) internal {
        ExecuteBuyParam memory param;
        param.nftAddr = _nftAddr;
        param.vault = _vault;
        param.orderId = _orderId;
        param.erc20Addr = _erc20;
        param.marketplace = _marketplace;
        _auth(param.vault);

        // 1. check price
        (bool success, bytes memory returnedData) = param
            .marketplace
            .staticcall(
                abi.encodeWithSignature("sellOrders(uint256)", param.orderId)
            );
        if (!success) {
            revert FiledPriceCheck();
        }

        (param.seller, param.tokenId, param.tokenPrice) = abi.decode(
            returnedData,
            (address, uint256, uint256)
        );

        uint256 balanceBefore = IERC20(param.erc20Addr).balanceOf(param.vault);

        (address treasury, uint256 cutRatio) = LibLiquidity.getProtocolFee();
        uint256 feeAmount = param
            .tokenPrice
            .wadToRay()
            .rayMul(cutRatio)
            .rayToWad();

        // 2. transfer money from escrow to vault
        bytes memory transferData = abi.encodeWithSignature(
            "transferUnderlyingTo(address,address,uint256)",
            param.erc20Addr,
            param.vault,
            param.tokenPrice * 2 + feeAmount
        );
        address escrow = VaultDataFacet(param.vault).creditEscrow(
            param.erc20Addr
        );
        _call(param.vault, escrow, transferData);

        // 3. protocol fee

        VaultAssetFacet(param.vault).transferReserve(
            param.erc20Addr,
            treasury,
            feeAmount
        );

        // 4. execute buy
        bytes memory callData = abi.encodeWithSignature(
            "buyCard(uint256)",
            _orderId
        );
        _call(param.vault, param.marketplace, callData);

        // 5. refund
        IERC20(param.erc20Addr).safeTransfer(
            escrow,
            IERC20(param.erc20Addr).balanceOf(param.vault) - balanceBefore
        );

        LibVault.updateNFTPrice(param.nftAddr, param.tokenId, param.tokenPrice);
        emit Order(
            param.nftAddr,
            param.vault,
            param.seller,
            param.tokenId,
            param.tokenPrice
        );
    }

    function _auth(address _vault) internal {
        if (LibVault.getVaultAddress(_msgSender()) != _vault) {
            revert UnAuthorised();
        }
    }

    function _call(
        address _vault,
        address _target,
        bytes memory _data
    ) internal returns (bytes memory) {
        VaultExternalFacet vef = VaultExternalFacet(_vault);
        return vef.callExternal(_target, _data);
    }
}

/* --------------------------------- errors -------------------------------- */
error FiledPriceCheck();
error UnAuthorised();

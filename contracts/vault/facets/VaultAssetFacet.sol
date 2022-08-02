// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {VaultConfig, NFTInfo} from "../../voyage/libraries/LibAppStorage.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";
import {SecurityFacet} from "../../voyage/facets/SecurityFacet.sol";
import {LoanFacet} from "../../voyage/facets/LoanFacet.sol";
import {VaultAuth} from "../libraries/LibAuth.sol";

contract VaultAssetFacet is
    ReentrancyGuard,
    Storage,
    IERC721Receiver,
    VaultAuth
{
    using SafeERC20 for IERC20;

    /// @notice Withdraw NFT from vault
    /// @param _currency The addresss of the reserve
    /// @param _collection The address of collection
    /// @param _tokenId Token id that being withdrawal
    function withdrawNFT(
        address _currency,
        address _collection,
        uint256 _tokenId
    ) external authorised {
        VaultFacet vf = VaultFacet(LibVaultStorage.ds().voyage);
        NFTInfo memory nftInfo = vf.getCollectionInfo(_collection, _tokenId);

        // 1. check if paid amount >= purchased price
        LoanFacet lf = LoanFacet(LibVaultStorage.ds().voyage);
        (uint256 totalPaid, uint256 totalRedeemed) = lf.getTotalPaidAndRedeemed(
            _currency,
            address(this)
        );
        if (totalPaid < totalRedeemed) {
            revert InvalidTotalPaidAndRedeemed(totalPaid, totalRedeemed);
        }
        uint256 availableAmount = totalPaid - totalRedeemed;
        if (availableAmount < nftInfo.price) {
            revert InvalidWithdrawal(availableAmount, nftInfo.price);
        }
        lf.increaseTotalRedeemed(_currency, address(this), nftInfo.price);

        // 3. transfer nft out
        IERC721(_collection).transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @notice Transfer nft out
    /// @param _collection The address of collection
    /// @param _to whom to transfer
    /// @param _tokenId Token id of the NFT to transfer
    function transferNFT(
        address _collection,
        address _to,
        uint256 _tokenId
    ) external nonReentrant onlyVoyage {
        IERC721(_collection).transferFrom(address(this), _to, _tokenId);
    }

    function transferReserve(
        address _currency,
        address _to,
        uint256 _amount
    ) external nonReentrant onlyVoyage {
        IERC20(_currency).safeTransfer(_to, _amount);
    }

    /// @notice Called by erc721 contract or sub vaults
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4 ret) {
        VaultFacet vf = VaultFacet(LibVaultStorage.ds().voyage);
        bool maybeSubVault = LibVaultStorage.ds().subvaultOwnerIndex[
            msg.sender
        ] != address(0);
        if (
            vf.getMarketPlaceByAsset(msg.sender) == address(0) && !maybeSubVault
        ) {
            revert InvalidSender(msg.sender);
        }
        // delete anyway
        delete LibVaultStorage.ds().custodyIndex[msg.sender][tokenId];
        return this.onERC721Received.selector;
    }

    /// @notice Withdraw rewards
    /// @param _currency Address of currency
    /// @param _receiver Address receives the withdrawing rewards
    /// @param _amount Amount transferred
    function withdrawRewards(
        address _currency,
        address _receiver,
        uint256 _amount
    ) external authorised {
        uint256 reserveBalance = IERC20(_currency).balanceOf(address(this));
        if (reserveBalance < _amount) {
            revert InsufficientFund(reserveBalance);
        }
        IERC20(_currency).safeTransfer(_receiver, _amount);
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidTotalPaidAndRedeemed(uint256 totalPaid, uint256 totalRedeemed);
error InvalidWithdrawal(uint256 availableAmount, uint256 nftPrice);
error InvalidSender(address sender);
error InsufficientFund(uint256 reserveBalance);
error InvalidAssetAddress();
error AssetInitialized();
error FailedDeployMarginEscrow();
error FailedDeployCreditEscrow();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {IMarginEscrow} from "../interfaces/IMarginEscrow.sol";
import {ICreditEscrow} from "../interfaces/ICreditEscrow.sol";
import {PriorityQueue, Heap} from "../libraries/PriorityQueue.sol";
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
    using PriorityQueue for Heap;
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

        // 2. remove from heap
        LibVaultStorage.ds().nfts[_collection].del(_tokenId, nftInfo.timestamp);

        // 3. transfer nft out
        IERC721(_collection).transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @notice Transfer nft out
    /// @param _collection The address of collection
    /// @param _to whom to transfer
    /// @param _num Number of nfts to transfer
    function transferNFT(
        address _collection,
        address _to,
        uint256 _num
    ) external nonReentrant onlyVoyage returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](_num);
        for (uint256 i = 0; i < _num; ) {
            uint256 tokenId;
            uint256 timestamp;
            (tokenId, timestamp) = LibVaultStorage
                .ds()
                .nfts[_collection]
                .delMin();
            IERC721(_collection).transferFrom(address(this), _to, tokenId);
            ids[i] = tokenId;
            unchecked {
                ++i;
            }
        }
        return ids;
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
        if (vf.getMarketPlaceByAsset(msg.sender) != address(0)) {
            LibVaultStorage.ds().nfts[msg.sender].insert(
                tokenId,
                block.timestamp
            );
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

    /// @notice Inititalizes a credit line the asset, deploying margin escrow and credit escrow
    /// @param _currency Address of currency
    /// @param _collection Address of collection
    function initCreditLine(address _currency, address _collection)
        public
        onlyVoyage
        returns (address, address)
    {
        if (_currency == address(0)) {
            revert InvalidAssetAddress();
        }
        VaultStorageV1 storage s = LibVaultStorage.ds();
        if (address(s.escrow[_currency]) != address(0)) {
            revert AssetInitialized();
        }
        BeaconProxy creditEscrowProxy = new BeaconProxy(
            address(
                VaultFacet(LibVaultStorage.ds().voyage).creditEscrowBeacon()
            ),
            abi.encodeWithSelector(
                ICreditEscrow(address(0)).initialize.selector,
                address(this)
            )
        );

        BeaconProxy marginEscrowProxy = new BeaconProxy(
            address(
                VaultFacet(LibVaultStorage.ds().voyage).marginEscrowBeacon()
            ),
            abi.encodeWithSelector(
                IMarginEscrow(address(0)).initialize.selector,
                address(this),
                s.voyage,
                _currency,
                _collection
            )
        );
        address _me = address(marginEscrowProxy);
        if (_me == address(0)) {
            revert FailedDeployMarginEscrow();
        }
        address _ce = address(creditEscrowProxy);
        if (_ce == address(0)) {
            revert FailedDeployCreditEscrow();
        }
        s.escrow[_currency] = _me;
        s.cescrow[_currency] = _ce;
        // max approve escrow
        IERC20(_currency).safeApprove(_ce, type(uint256).max);
        IERC20(_currency).safeApprove(_me, type(uint256).max);
        return (_me, _ce);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {VaultStorageV1, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {IMarginEscrow} from "../interfaces/IMarginEscrow.sol";
import {ICreditEscrow} from "../interfaces/ICreditEscrow.sol";
import {PriorityQueue, Heap} from "../libraries/PriorityQueue.sol";
import {VaultConfig, NFTInfo} from "../../voyage/libraries/LibAppStorage.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";
import {LoanFacet} from "../../voyage/facets/LoanFacet.sol";

contract VaultAssetFacet is ReentrancyGuard, Storage, IERC721Receiver {
    using SafeMath for uint256;
    using PriorityQueue for Heap;
    using SafeERC20 for IERC20;

    /// @notice Withdraw NFT from vault
    /// @param _reserve The addresss of the reserve
    /// @param _reserve NFT address
    /// @param _tokenId Token id that being withdrawal
    function withdrawNFT(
        address _reserve,
        address _erc721Addr,
        uint256 _tokenId
    ) external onlyOwner {
        VaultFacet vf = VaultFacet(LibVaultStorage.diamondStorage().voyage);
        NFTInfo memory nftInfo = vf.getNFTInfo(_erc721Addr, _tokenId);

        // 1. check if paid amount >= purchased price
        LoanFacet lf = LoanFacet(LibVaultStorage.diamondStorage().voyage);
        (uint256 totalPaid, uint256 totalRedeemed) = lf.getTotalPaidAndRedeemed(
            _reserve,
            address(this)
        );
        if (totalPaid < totalRedeemed) {
            revert InvalidTotalPaidAndRedeemed(totalPaid, totalRedeemed);
        }
        uint256 availableAmount = totalPaid.sub(totalRedeemed);
        if (availableAmount < nftInfo.price) {
            revert InvalidWithdrawal(availableAmount, nftInfo.price);
        }
        lf.increaseTotalRedeemed(_reserve, address(this), nftInfo.price);

        // 2. remove from heap
        LibVaultStorage.diamondStorage().nfts[_erc721Addr].del(
            _tokenId,
            nftInfo.timestamp
        );

        // 3. transfer nft out
        IERC721(_erc721Addr).transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @notice Transfer nft out
    /// @param _erc721Addr NFT address
    /// @param _to whom to transfer
    /// @param _num Number of nfts to transfer
    function transferNFT(
        address _erc721Addr,
        address _to,
        uint256 _num
    ) external nonReentrant onlyVoyage {
        for (uint256 i = 0; i < _num; i++) {
            uint256 tokenId;
            uint256 timestamp;
            (tokenId, timestamp) = LibVaultStorage
                .diamondStorage()
                .nfts[_erc721Addr]
                .delMin();
            IERC721(_erc721Addr).transferFrom(address(this), _to, tokenId);
        }
    }

    /// @notice Called by erc721 contract or sub vaults
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4 ret) {
        VaultFacet vf = VaultFacet(LibVaultStorage.diamondStorage().voyage);
        bool maybeSubVault = LibVaultStorage
            .diamondStorage()
            .subvaultOwnerIndex[msg.sender] != address(0);
        if (
            vf.getMarketPlaceByAsset(msg.sender) == address(0) && !maybeSubVault
        ) {
            revert InvalidSender(msg.sender);
        }
        if (vf.getMarketPlaceByAsset(msg.sender) != address(0)) {
            LibVaultStorage.diamondStorage().nfts[msg.sender].insert(
                tokenId,
                block.timestamp
            );
        }
        // delete anyway
        delete LibVaultStorage.diamondStorage().custodyIndex[msg.sender][
            tokenId
        ];
    }

    /// @notice Withdraw rewards
    /// @param _reserve Address of reserve
    /// @param _receiver Address receives the withdrawing rewards
    /// @param _amount Amount transferred
    function withdrawRewards(
        address _reserve,
        address _receiver,
        uint256 _amount
    ) external onlyOwner {
        uint256 reserveBalance = IERC20(_reserve).balanceOf(address(this));
        if (reserveBalance < _amount) {
            revert InsufficientFund(reserveBalance);
        }
        IERC20(_reserve).safeTransfer(_receiver, _amount);
    }

    /// @notice Init asset, deploying margin escrow and credit escrow
    /// @param _asset Address of reserve
    function initAsset(address _asset) public onlyVoyage returns (address) {
        if (_asset == address(0)) {
            revert InvalidAssetAddress();
        }
        VaultStorageV1 storage s = LibVaultStorage.diamondStorage();
        if (address(s.escrow[_asset]) != address(0)) {
            revert AssetInitialized();
        }
        BeaconProxy creditEscrowProxy = new BeaconProxy(
            address(
                VaultFacet(LibVaultStorage.diamondStorage().voyage)
                    .creditEscrowBeacon()
            ),
            abi.encodeWithSelector(
                ICreditEscrow(address(0)).initialize.selector,
                address(this)
            )
        );

        BeaconProxy marginEscrowProxy = new BeaconProxy(
            address(
                VaultFacet(LibVaultStorage.diamondStorage().voyage)
                    .marginEscrowBeacon()
            ),
            abi.encodeWithSelector(
                IMarginEscrow(address(0)).initialize.selector,
                address(this),
                s.voyage,
                _asset
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
        s.escrow[_asset] = _me;
        s.cescrow[_asset] = _ce;
        // max approve escrow
        IERC20(_asset).safeApprove(_ce, type(uint256).max);
        IERC20(_asset).safeApprove(_me, type(uint256).max);
        return _me;
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

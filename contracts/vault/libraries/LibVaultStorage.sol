// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {PriorityQueue, Heap} from "./PriorityQueue.sol";
import {IMarginEscrow} from "../interfaces/IMarginEscrow.sol";

struct CustodyData {
    // the "owner" of the token -- must be Vault or a Subvault.
    address owner;
    // the current holder of the token, e.g., battle game.
    address custodian;
}

struct VaultStorageV1 {
    address owner;
    address voyage;
    // asset (ERC20) => escrow
    mapping(address => address) cescrow;
    mapping(address => address) escrow;
    // erc721 address => heap
    mapping(address => Heap) nfts;
    /// @dev You must not set element 0xffffffff to true
    mapping(bytes4 => bool) supportedInterfaces;
    // subvault array, for retrieval by DataProviderFacet and client-side enumeration
    address[] subvaults;
    // mapping of subvault to owner
    mapping(address => address) subvaultOwnerIndex;
    // mapping of owner to subvault
    mapping(address => address) ownerSubvaultIndex;
    // mapping of subvault => paused status
    mapping(address => bool) subvaultStatusIndex;
    mapping(address => uint256[]) tokenSet;
    // mapping of erc721 address to mapping of tokenId to custody information
    // to save storage space, only store this data if the token is transferred out of the Vault (i.e., to a Subvault or external contract)
    mapping(address => mapping(uint256 => CustodyData)) custodyIndex;
}

library LibVaultStorage {
    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (VaultStorageV1 storage ds)
    {
        // Specifies a random position in contract storage
        // This can be done with a keccak256 hash of a unique string as is
        // done here or other schemes can be used such as this:
        // bytes32 storagePosition = keccak256(abi.encodePacked(ERC1155.interfaceId, ERC1155.name, address(this)));
        bytes32 storagePosition = keccak256("finance.voyage.vault.v1.storage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}

contract Storage {
    modifier onlyVoyage() {
        require(
            msg.sender == LibVaultStorage.diamondStorage().voyage,
            "Not Voyage"
        );
        _;
    }

    modifier onlyOwner() {
        //        VaultFacet vf = VaultFacet(LibVaultStorage.diamondStorage().voyage);
        //        address vault = vf.getVaultAddr(msg.sender);
        //        require(vault == address(this), "Vault: not owner");
        _;
    }

    function _marginEscrow(address _asset)
        internal
        view
        returns (IMarginEscrow)
    {
        return IMarginEscrow(LibVaultStorage.diamondStorage().escrow[_asset]);
    }
}

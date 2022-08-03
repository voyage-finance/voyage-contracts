// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

struct CustodyData {
    // the "owner" of the token -- must be Vault or a Subvault.
    address owner;
    // the current holder of the token, e.g., battle game.
    address custodian;
}

struct VaultStorageV1 {
    address owner;
    address voyage;
    address user;
    uint256 version;
    bytes32 checksum;
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
    mapping(address => mapping(uint256 => bool)) withdrawableAssets;
}

library LibVaultStorage {
    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function ds() internal pure returns (VaultStorageV1 storage ds) {
        // Set the position of our struct in contract storage
        bytes32 storagePosition = keccak256("diamond.storage.vault.voyage");
        assembly {
            ds.slot := storagePosition
        }
    }
}

contract Storage {
    modifier onlyVoyage() {
        require(msg.sender == LibVaultStorage.ds().voyage, "Not Voyage");
        _;
    }
}

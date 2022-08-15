// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IVault} from "./Vault.sol";

interface ISubvault {
    function initialize(address _parent, address _owner) external;

    function updateOwner(address _newOwner) external;

    function callExternal(address target, bytes calldata data)
        external
        returns (bytes memory);
}

contract SubVault is Initializable, ISubvault, IERC721Receiver {
    struct SubVaultStorageV1 {
        address owner;
        address parent;
    }

    // only `parent` should be able to call
    modifier authorised() {
        require(msg.sender == diamondStorage().parent, "SubVault: only parent");
        _;
    }

    function initialize(address _owner, address _parent) external initializer {
        diamondStorage().owner = _owner;
        diamondStorage().parent = _parent;
    }

    function callExternal(address target, bytes calldata data)
        external
        authorised
        returns (bytes memory)
    {
        (bool success, bytes memory ret) = target.call(data);
        require(success);
        return ret;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4 ret) {
        if (
            !IVault(diamondStorage().parent).collectionInitialized(msg.sender)
        ) {
            revert InvalidSenderAddress();
        }
        IVault(diamondStorage().parent).onERC721Transferred(
            msg.sender,
            tokenId,
            from,
            address(this)
        );
    }

    function updateOwner(address _newOwner) external authorised {
        diamondStorage().owner = _newOwner;
    }

    function getOwner() public view returns (address) {
        return diamondStorage().owner;
    }

    /************************************** Internal Functions **************************************/

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function diamondStorage()
        internal
        pure
        returns (SubVaultStorageV1 storage ds)
    {
        // Specifies a random position in contract storage
        // This can be done with a keccak256 hash of a unique string as is
        // done here or other schemes can be used such as this:
        // bytes32 storagePosition = keccak256(abi.encodePacked(ERC1155.interfaceId, ERC1155.name, address(this)));
        bytes32 storagePosition = keccak256(
            "finance.voyage.subvault.v1.storage"
        );
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}

/* --------------------------------- errors -------------------------------- */
error InvalidSenderAddress();

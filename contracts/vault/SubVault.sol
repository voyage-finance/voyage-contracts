// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Vault} from "./Vault.sol";
import {VaultAssetFacet} from "./facets/VaultAssetFacet.sol";
import {VaultDataFacet} from "./facets/VaultDataFacet.sol";
import {VaultManageFacet} from "./facets/VaultManageFacet.sol";
import {ISubvault} from "./interfaces/ISubvault.sol";
import {Call} from "./interfaces/ICallExternal.sol";

contract SubVault is Initializable, IERC1271, ISubvault, IERC721Receiver {
    struct SubVaultStorageV1 {
        address owner;
        address parent;
    }

    // only `parent` or `owner` should be able to call
    modifier authorised() {
        require(
            msg.sender == diamondStorage().parent ||
                msg.sender == diamondStorage().owner,
            "SubVault: unauthorised"
        );
        _;
    }
    // only parent
    modifier parent() {
        require(msg.sender == diamondStorage().parent, "SubVault: only parent");
        _;
    }

    // only the owner of this Subvault
    modifier owner() {
        require(msg.sender == diamondStorage().owner, "SubVault: only owner");
        _;
    }

    function initialize(address _owner, address _parent) external initializer {
        diamondStorage().owner = _owner;
        diamondStorage().parent = _parent;
    }

    function callExternal(Call[] calldata calls)
        external
        authorised
        returns (bytes[] memory ret)
    {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4 ret) {
        require(
            VaultDataFacet(diamondStorage().parent).isValidERC721(msg.sender),
            "SubVault#onERC721Received: invalid sender"
        );
        VaultManageFacet(diamondStorage().parent).onERC721Transferred(
            msg.sender,
            tokenId,
            from,
            address(this)
        );
    }

    function updateOwner(address _newOwner) external parent {
        diamondStorage().owner = _newOwner;
    }

    /// @notice Should return whether the signature provided is valid for the provided data
    /// @param hash      Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        address sender = recoverSigner(hash, signature);
        if (diamondStorage().owner == sender) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
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

    /// @notice Recover the signer of hash, assuming it's an EOA account
    /// @dev Only for EthSign signatures
    /// @param _hash       Hash of message that was signed
    /// @param _signature  Signature encoded as (bytes32 r, bytes32 s, uint8 v)
    function recoverSigner(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address signer)
    {
        require(
            _signature.length == 65,
            "SignatureValidator#recoverSigner: invalid signature length"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        //
        // Source OpenZeppelin
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert(
                "SignatureValidator#recoverSigner: invalid signature 's' value"
            );
        }

        if (v != 27 && v != 28) {
            revert(
                "SignatureValidator#recoverSigner: invalid signature 'v' value"
            );
        }

        // Recover ECDSA signer
        signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ),
            v,
            r,
            s
        );

        // Prevent signer from being 0x0
        require(
            signer != address(0x0),
            "SignatureValidator#recoverSigner: INVALID_SIGNER"
        );

        return signer;
    }
}

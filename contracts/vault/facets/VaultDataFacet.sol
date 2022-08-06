// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {CustodyData, LibVaultStorage, Storage} from "../libraries/LibVaultStorage.sol";
import {VaultConfig} from "../../voyage/libraries/LibAppStorage.sol";
import {LoanFacet} from "../../voyage/facets/LoanFacet.sol";
import {VaultFacet} from "../../voyage/facets/VaultFacet.sol";
import {DataProviderFacet} from "../../voyage/facets/DataProviderFacet.sol";

contract VaultDataFacet is ReentrancyGuard, Storage, IERC1271 {
    /// @notice Get total debt of this vault
    /// @param _collection Address of the collection
    function totalDebt(address _collection)
        public
        view
        returns (uint256 total)
    {
        uint256 principal;
        uint256 interest;
        (principal, interest) = LoanFacet(LibVaultStorage.ds().voyage)
            .getVaultDebt(_collection, address(this));
        total = principal + interest;
    }

    /// @notice Get margin requirement
    /// @param _collection Address of the nft collection
    function marginRequirement(address _collection)
        public
        view
        returns (uint256)
    {
        VaultConfig memory vc = VaultFacet(LibVaultStorage.ds().voyage)
            .getVaultConfig(_collection, address(this));
        return vc.marginRequirement;
    }

    /// @notice Get token status
    /// @param _collection The address of the ERC721 contract
    /// @param _tokenId Token id
    function getTokenStatus(address _collection, uint256 _tokenId)
        public
        view
        returns (CustodyData memory)
    {
        return LibVaultStorage.ds().custodyIndex[_collection][_tokenId];
    }

    /// @notice Get token list owned by this vault
    /// @param _collection The address of the ERC721 contract
    function getTokensOwned(address _collection)
        public
        view
        returns (uint256[] memory)
    {
        return LibVaultStorage.ds().tokenSet[_collection];
    }

    /// @notice Get sub vault address of a specific user
    /// @param _owner The address of the user
    function getSubvaultOf(address _owner) public view returns (address) {
        return LibVaultStorage.ds().ownerSubvaultIndex[_owner];
    }

    /// @notice Get sub vault's address
    /// @param _subvault The address of the subvault
    function getSubvaultStatus(address _subvault) public view returns (bool) {
        return LibVaultStorage.ds().subvaultStatusIndex[_subvault];
    }

    function isValidERC721(address _collection) public view returns (bool) {
        VaultFacet vf = VaultFacet(LibVaultStorage.ds().voyage);
        return vf.getMarketPlaceByCollection(_collection) != address(0);
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
        if (LibVaultStorage.ds().user == sender) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
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

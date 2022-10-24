// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {IOracleFacet, Message} from "../interfaces/IOracleFacet.sol";

// Inspired by https://github.com/ZeframLou/trustus
contract OracleFacet is IOracleFacet {
    function verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) external view returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            return false;
        }

        // Ensure the message timestamp is valid
        if (
            message.timestamp > block.timestamp ||
            message.timestamp + validFor < block.timestamp
        ) {
            return false;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;

        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            return false;
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Message(bytes32 id,bytes payload,uint256 timestamp)"
                            ),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == LibAppStorage.ds().oracleSignerAddress;
    }

    function getMessageId(address _collection) external pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "ContractWideCollectionPrice(uint8 kind,uint256 twapHours,address contract)"
                    ),
                    1, // PriceKind.TWAP
                    24, // 24 hours TWAP
                    _collection
                )
            );
    }
}
/* --------------------------------- errors -------------------------------- */
error InvalidTwapMessageId();
error InvalidTwapMessageSignature();
error InvalidTwapTimestamp();

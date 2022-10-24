// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

struct Message {
    bytes32 id;
    bytes payload;
    // The UNIX timestamp when the message was signed by the oracle
    uint256 timestamp;
    // ECDSA signature or EIP-2098 compact signature
    bytes signature;
}

interface IOracleFacet {
    function verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) external returns (bool success);

    function getMessageId(address _collection) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/Escrow.sol';

contract SecurityDepositEscrow is Escrow {
    function getVersion() external view returns (string memory) {
        string memory version = 'SecurityDepositEscrow 0.0.1';
        return version;
    }
}

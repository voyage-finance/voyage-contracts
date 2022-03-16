// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/Escrow.sol';

contract SecurityDepositEscrow is Escrow {
    function getVersion() external view returns (string memory) {
        string memory version = 'SecurityDepositEscrow 0.0.1';
        return version;
    }

    // placeholder function
    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) public payable nonReentrant onlyOwner {
        transferToUser(_reserve, _to, _amount);
    }
}

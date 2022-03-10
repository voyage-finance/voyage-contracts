// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultManager {
    function initialize(address) external;

    function getMaxSecurityDeposit(address _reserve)
        external
        view
        returns (uint256);
}

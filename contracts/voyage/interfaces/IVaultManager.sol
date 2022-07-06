// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVaultManager {
    function createSubvault(address _owner) external returns (address);

    function updateSubvaultOwner(address _subvault, address _newOwner) external;

    function pauseSubvault(address _subvault) external;

    function unpauseSubvault(address _subvault) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IMessageBus {
    function getAddressResolverAddress() external view returns (address);

    function getVault(address _user) external view returns (address);

    function getMaxSecurityDeposit(address _reserve)
        external
        view
        returns (uint256);

    function getSecurityDepositRequirement(address _reserve)
        external
        view
        returns (uint256);
}

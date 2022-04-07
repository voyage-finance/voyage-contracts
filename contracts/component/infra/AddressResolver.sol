// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../interfaces/IAddressResolver.sol';
import '../../libraries/ownership/Ownable.sol';

contract AddressResolver is IAddressResolver, Ownable {
    mapping(bytes32 => address) public repository;

    function importAddresses(
        bytes32[] calldata names,
        address[] calldata destinations
    ) external onlyOwner {
        require(
            names.length == destinations.length,
            'Input lengths must match'
        );

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address)
    {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }
}

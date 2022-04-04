// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../ownership/Ownable.sol';

abstract contract State is Ownable {
    mapping(address => bool) public associatedContracts;

    constructor(address _associatedContract) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), 'Owner must be set');

        associatedContracts[_associatedContract] = true;
        emit AssociatedContractUpdated(_associatedContract);
    }

    event AssociatedContractUpdated(address associatedContract);

    modifier onlyAssociatedContract() {
        require(
            associatedContracts[msg.sender],
            'Only the associated contract can perform this action'
        );
        _;
    }

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContracts[_associatedContract] = true;
        emit AssociatedContractUpdated(_associatedContract);
    }
}

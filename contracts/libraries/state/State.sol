// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../ownership/Ownable.sol';

abstract contract State is Ownable {
    address public associatedContract;

    constructor(address _associatedContract) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), 'Owner must be set');

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    event AssociatedContractUpdated(address associatedContract);

    modifier onlyAssociatedContract() {
        require(
            msg.sender == associatedContract,
            'Only the associated contract can perform this action'
        );
        _;
    }

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }
}

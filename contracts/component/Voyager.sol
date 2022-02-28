// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/ownership/Ownable.sol';

contract Voyager is Ownable {
    address public addressResolver;

    /**
     * @dev Update addressResolver contract address
     * @param _addressResolver address of the resolver contract
     **/
    function setAddressResolverAddress(address _addressResolver)
        external
        onlyOwner
    {
        addressResolver = _addressResolver;
    }

    /**
     * @dev Get addressResolver contract address
     * @return address of the resolver contract
     **/
    function getAddressResolverAddress() external view returns (address) {
        return addressResolver;
    }
}

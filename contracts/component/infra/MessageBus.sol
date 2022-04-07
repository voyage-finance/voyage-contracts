// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './AddressResolver.sol';
import '../../interfaces/IMessageBus.sol';

contract MessageBus is IMessageBus {
    AddressResolver public addressResolver;

    /**
     * @dev Get addressResolver contract address
     * @return address of the resolver contract
     **/
    function getAddressResolverAddress() external view returns (address) {
        return address(addressResolver);
    }
}

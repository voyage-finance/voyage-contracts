// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {DataTypes} from "../libraries/types/DataTypes.sol";

import {AddressResolver} from "../component/infra/AddressResolver.sol";

interface IMessageBus {
    function addressResolver() external view returns (AddressResolver);

    function getVault(address _user) external view returns (address);

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256);
}

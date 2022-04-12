// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/types/DataTypes.sol';

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

    function getReserveData(address _asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getSecurityDeposit(address _user, address _reserve)
        external
        view
        returns (uint256);

    function getCompoundedDebt(address _user) public view returns (uint256);

    function getAggregateOptimalRepaymentRate(address _user)
        public
        view
        returns (uint256);

    function getAggregateActualRepaymentRate(address _user)
        public
        view
        returns (uint256);
}

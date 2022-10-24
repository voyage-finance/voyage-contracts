// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IRepaymentFacet {
    function repay(
        address _collection,
        uint256 _loan,
        address payable _vault
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ILiquidateFacet {
    function liquidate(
        address _collection,
        address _vault,
        uint256 _loanId
    ) external;
}

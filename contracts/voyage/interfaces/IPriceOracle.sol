// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IPriceOracle {
    function getTwap(address _asset) external view returns (uint256, uint256);

    function updateTwap(address _asset, uint256 _priceAverage) external;
}

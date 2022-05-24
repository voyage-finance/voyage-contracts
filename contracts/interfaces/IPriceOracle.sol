// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IPriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function updateAssetPrice(address _asset) external;

    function update(address _asset, uint256 _price) external;
}

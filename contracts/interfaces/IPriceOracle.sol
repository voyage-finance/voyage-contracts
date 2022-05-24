// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IPriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function updateAssetPrice(address _asset) external;

    function updateAssetPrices(address[] calldata _assets) external;

    function updateCumulative(address _asset, uint256 _price) external;

    function updateCumulativeBatch(
        address[] calldata _assets,
        uint256[] calldata _prices
    ) external;
}

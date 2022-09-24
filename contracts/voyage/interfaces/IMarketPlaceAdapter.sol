// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

struct AssetInfo {
    uint256 tokenId;
    uint256 assetPrice;
    address currency;
}

interface IMarketPlaceAdapter {
    function extractAssetInfo(bytes calldata _data)
        external
        pure
        returns (AssetInfo memory);

    function validate(bytes calldata _data) external view returns (bool);

    function execute(
        bytes calldata _data,
        address _vault,
        address _marketplace,
        uint256 _value
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IMarketPlaceAdapter {
    function extractAssetPrice(bytes calldata _data)
        external
        pure
        returns (uint256);

    function validate(bytes calldata _data) external pure returns (bool);

    function execute(bytes calldata _data) external pure returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IExternalAdapter {
    function validate(
        address vault,
        address target,
        bytes4 selector,
        bytes calldata payload
    )
        external
        returns (
            address[] memory,
            bytes[] memory,
            address[] memory,
            bytes[] memory
        );

    function getERC721() external returns (address);
}

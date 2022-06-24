// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IExternalAdapter {
    function validate(
        address target,
        bytes4 selector,
        bytes calldata payload
    ) external returns (address, bytes memory);

    function getERC721() external returns (address);
}

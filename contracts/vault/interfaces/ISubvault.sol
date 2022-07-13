// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ISubvault {
    function initialize(address _parent, address _owner) external;

    function updateOwner(address _newOwner) external;
}

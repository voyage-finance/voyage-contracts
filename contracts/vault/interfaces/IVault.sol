// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVault {
    function initialize(
        address _owner,
        address _user,
        address _cutFacet,
        address _loupeFacet,
        address _ownershipFacet
    ) external;
}

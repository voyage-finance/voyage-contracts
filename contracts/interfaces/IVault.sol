// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IVault {
    function depositSecurity(
        address _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable;

    function redeemSecurity(
        address payable _sponsor,
        address _reserve,
        uint256 _amount
    ) external payable;

    function increaseTotalDebt(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../component/vault/SecurityDepositEscrow.sol';

interface IVault {
    function initialize(
        address _voyager,
        SecurityDepositEscrow _securityDepositEscrow
    ) external;

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

    function slash(
        address _reserve,
        address payable _to,
        uint256 _amount
    ) external;

    function initStakingContract(address _reserve) external;

    function getSecurityDepositTokenAddress() external view returns (address);

    function initSecurityDepositToken(address _reserve) external;

    function eligibleAmount(address _reserve, address _sponsor)
        external
        view
        returns (uint256);

    function underlyingBalance(address _sponsor, address _reserve)
        external
        view
        returns (uint256);

    function getTotalDebt() external view returns (uint256);

    function getCurrentSecurityDeposit(address _reserve)
        external
        view
        returns (uint256);
}
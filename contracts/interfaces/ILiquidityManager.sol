// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/logic/ReserveLogic.sol';

interface ILiquidityManager {
    event Deposit(
        address indexed reserve,
        ReserveLogic.Tranche tranche,
        address user,
        address indexed onBehalfOf,
        uint256 amount
    );

    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);

    function getEscrowAddress() external view returns (address);
}

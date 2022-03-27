// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/logic/ReserveLogic.sol';

interface ILiquidityManager {
    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);
}

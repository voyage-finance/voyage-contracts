// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/logic/ReserveLogic.sol';

interface ILiquidityManager {
    function getReserveNormalizedIncome(
        address _asset,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);

    function getEscrowAddress() external view returns (address);

    function deposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address _user,
        address _onBehalfOf
    ) external;

    function withdraw(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address payable _user
    ) external;

    function withdrawAbleAmount(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);

    function balance(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);
}

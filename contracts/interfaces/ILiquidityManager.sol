// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../libraries/logic/ReserveLogic.sol";

interface ILiquidityManager {
    function deposit(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address _user
    ) external;

    function withdraw(
        address _asset,
        ReserveLogic.Tranche _tranche,
        uint256 _amount,
        address payable _user
    ) external;

    function unbonding(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);

    function balance(
        address _reserve,
        address _user,
        ReserveLogic.Tranche _tranche
    ) external view returns (uint256);

    function utilizationRate(address _reserve) external view returns (uint256);
}

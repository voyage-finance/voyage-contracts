// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './ReserveManager.sol';

contract LiquidityManager is ReserveManager {
    constructor(address payable _proxy, address _voyager)
        ReserveManager(_proxy, _voyager)
    {}
}

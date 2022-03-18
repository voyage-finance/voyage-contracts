// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/state/State.sol';

contract LiquidityStorage is State {
    constructor(address _liquidityManager) State(_liquidityManager) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxyable.sol';
import '../Voyager.sol';

contract LiquidityManager is Proxyable {
    Voyager public voyager;

    constructor(address payable _proxy, address _voyager)
        public
        Proxyable(_proxy)
    {
        voyager = Voyager(_voyager);
    }
}

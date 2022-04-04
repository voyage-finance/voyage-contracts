// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxyable.sol';

contract LoanManager is Proxyable {
    constructor(address payable _proxy) Proxyable(_proxy) {}
}

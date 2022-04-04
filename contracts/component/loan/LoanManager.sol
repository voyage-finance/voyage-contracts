// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxyable.sol';
import '../../interfaces/IVoyagerComponent.sol';
import '../Voyager.sol';

contract LoanManager is Proxyable, IVoyagerComponent {
    constructor(address payable _proxy, address _voyager) Proxyable(_proxy) {
        voyager = Voyager(_voyager);
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
    }

    function borrow(
        address _asset,
        uint256 _amount,
        address _onBehalfOf
    ) external {}

    function _executeBorrow(ExecuteBorrowParams memory vars) internal {}
}

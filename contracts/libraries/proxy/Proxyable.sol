// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './Proxy.sol';
import '../ownership/Ownable.sol';

abstract contract Proxyable is Ownable {
    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    modifier onlyProxy() {
        _onlyProxy();
        _;
    }

    modifier optionalProxy_onlyOwner() {
        _optionalProxy_onlyOwner();
        _;
    }

    event ProxyUpdated(address proxyAddress);

    constructor(address payable _proxy) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), 'Owner must be set');

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, 'Only the proxy can call');
    }

    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, 'Owner only function');
    }
}
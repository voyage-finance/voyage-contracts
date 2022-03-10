// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/IVaultManager.sol';

contract VaultManagerProxy is Proxy {
    function getMaxSecurityDeposit(address _reserve)
        public
        view
        returns (uint256)
    {
        return IVaultManager(address(target)).getMaxSecurityDeposit(_reserve);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../libraries/proxy/Proxy.sol';
import '../../interfaces/ILiquidityManager.sol';
import '../../libraries/logic/ReserveLogic.sol';

contract LiquidityManagerProxy is Proxy {
    function getLiquidityRate(address _reserve, ReserveLogic.Tranche _tranche)
        external
        view
        returns (uint256)
    {
        return
            ILiquidityManager(address(target)).getLiquidityRate(
                _reserve,
                _tranche
            );
    }
}

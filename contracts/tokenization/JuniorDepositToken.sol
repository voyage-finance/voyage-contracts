// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../contracts/component/liquiditymanager/LiquidityManagerProxy.sol';
import '../libraries/helpers/Errors.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';

contract SecurityDepositToken is Context {
    LiquidityManagerProxy internal _liquidityManagerProxy;
    address internal _underlying;

    uint256 public constant JUNIOR_DEPOSIT_TOKEN_REVISION = 0x1;

    modifier onlyLiquidityManagerProxy() {
        require(
            _msgSender() == address(_liquidityManagerProxy),
            Errors.CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL
        );
        _;
    }
}

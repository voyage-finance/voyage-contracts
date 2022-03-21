// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../contracts/component/liquiditymanager/LiquidityManagerProxy.sol';
import '../libraries/helpers/Errors.sol';
import '../interfaces/IInitializableDepositToken.sol';
import './base/BaseERC20.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';

contract JuniorDepositToken is
    Context,
    BaseERC20('JuniorDepositToken_IMPL', 'JuniorDepositToken_IMPL', 0)
{
    LiquidityManagerProxy internal liquidityManagerProxy;
    address internal underlyingAsset;

    uint256 public constant JUNIOR_DEPOSIT_TOKEN_REVISION = 0x1;

    modifier onlyLiquidityManagerProxy() {
        require(
            _msgSender() == address(liquidityManagerProxy),
            Errors.CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL
        );
        _;
    }

    function initialize(
        LiquidityManagerProxy _liquidityManagerProxy,
        address _underlyingAsset,
        uint8 _juniorDepositTokenDecimals,
        string calldata _juniorDepositTokenName,
        string calldata _juniorDepositTokenSymbol,
        bytes calldata params
    ) external {
        _setName(_juniorDepositTokenName);
        _setSymbol(_juniorDepositTokenSymbol);
        _setDecimals(_juniorDepositTokenDecimals);

        liquidityManagerProxy = _liquidityManagerProxy;
        underlyingAsset = _underlyingAsset;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../contracts/component/liquiditymanager/LiquidityManagerProxy.sol';
import '../libraries/helpers/Errors.sol';
import '../interfaces/IInitializableDepositToken.sol';
import './BaseDepositERC20.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';
import '../libraries/math/WadRayMath.sol';

contract JuniorDepositToken is
    Context,
    IInitializableDepositToken,
    BaseDepositERC20('JuniorDepositToken_IMPL', 'JuniorDepositToken_IMPL', 0)
{
    using WadRayMath for uint256;
    using SafeMath for uint256;

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

    /**
     * @dev Initializes the JuniorDepositToken
     * @param _liquidityManagerProxy The address of the liquidity manager proxy
     * @param _underlyingAsset The address of the underlying asset of this JuniorDepositToken
     * @param _juniorDepositTokenDecimals The decimals of the JuniorDepositToken, same as the underlying asset's
     * @param _juniorDepositTokenName The name of the JuniorDepositToken
     * @param _juniorDepositTokenSymbol The symbol of the JuniorDepositToken
     **/
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

        emit Initialized(
            _underlyingAsset,
            address(_liquidityManagerProxy),
            _juniorDepositTokenDecimals,
            _juniorDepositTokenName,
            _juniorDepositTokenSymbol,
            params
        );
    }

    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external onlyLiquidityManagerProxy {
        uint256 previousBalance = super.balanceOf(user);
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
    }
}

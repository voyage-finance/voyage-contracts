// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../contracts/component/liquiditymanager/LiquidityManagerProxy.sol';
import '../libraries/helpers/Errors.sol';
import '../interfaces/IInitializableDepositToken.sol';
import './BaseDepositERC20.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../libraries/math/WadRayMath.sol';

contract JuniorDepositToken is
    Context,
    IInitializableDepositToken,
    BaseDepositERC20('JuniorDepositToken_IMPL', 'JuniorDepositToken_IMPL', 0)
{
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
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
        bytes calldata _params
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
            _params
        );
    }

    /**
     * @dev Mints `_amount` junior deposit token to `_user`
     * @param _user The address receiving the minted tokens
     * @param _amount The amount of tokens getting minted
     * @param _index The new liquidity index of the reserve
     * @return `true` if the previous balance of the user was 0
     **/
    function mint(
        address _user,
        uint256 _amount,
        uint256 _index
    ) external onlyLiquidityManagerProxy returns (bool) {
        uint256 previousBalance = super.balanceOf(_user);
        uint256 amountScaled = _amount.rayDiv(_index);
        require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
        _mint(_user, amountScaled);
        emit Transfer(address(0), _user, _amount);
        emit Mint(_user, _amount, _index);

        return previousBalance == 0;
    }

    /**
     * @dev Burns JuniorDepositToken from `_user` and sends the equivalent amount of underlying to `_receiverOfUnderlying`
     * - Only callable by the LiquidityManagerProxy, as extra state updates there need to the managed
     * @param _user The owner of the JuniorDepositToken, getting them burned
     * @param _receiverOfUnderlying The address that will receive the underlying
     * @param _amount The amount being burned
     * @param _index The new liquidity index of the reserve
     **/
    function burn(
        address _user,
        address _receiverOfUnderlying,
        uint256 _amount,
        uint256 _index
    ) external onlyLiquidityManagerProxy {
        uint256 amountScaled = _amount.rayDiv(_index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
        _burn(_user, amountScaled);
        IERC20(underlyingAsset).safeTransfer(_receiverOfUnderlying, _amount);
        emit Transfer(_user, address(0), _amount);
        emit Burn(_user, _receiverOfUnderlying, _amount, _index);
    }
}

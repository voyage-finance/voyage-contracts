// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../../contracts/component/liquidity/LiquidityManagerProxy.sol';
import '../libraries/helpers/Errors.sol';
import './IInitializableDepositToken.sol';
import '../interfaces/ILiquidityManagerProxy.sol';
import './BaseERC20.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import '../libraries/math/WadRayMath.sol';
import '../libraries/logic/ReserveLogic.sol';
import '../component/infra/AddressResolver.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IVToken.sol';

contract SeniorDepositToken is
    Context,
    IInitializableDepositToken,
    BaseERC20('SeniorDepositToken_IMPL', 'SeniorDepositToken_IMPL', 0),
    IVToken
{
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    AddressResolver internal addressResolver;
    address internal underlyingAsset;

    uint256 public constant SENIOR_DEPOSIT_TOKEN_REVISION = 0x1;

    modifier onlyAdmin() {
        require(
            _msgSender() == addressResolver.getAddress('liquidityManager') ||
                _msgSender() == addressResolver.getAddress('loanManager'),
            Errors.CT_CALLER_MUST_BE_LIQUIDITY_MANAGER_POOL
        );
        _;
    }

    /**
     * @dev Initializes the JuniorDepositToken
     * @param _addressResolver The address of the AddressResolver
     * @param _underlyingAsset The address of the underlying asset of this SeniorDepositToken
     * @param _seniorDepositTokenDecimals The decimals of the SeniorDepositToken, same as the underlying asset's
     * @param _seniorDepositTokenName The name of the SeniorDepositToken
     * @param _seniorDepositTokenSymbol The symbol of the SeniorDepositToken
     **/
    function initialize(
        AddressResolver _addressResolver,
        address _underlyingAsset,
        uint8 _seniorDepositTokenDecimals,
        string calldata _seniorDepositTokenName,
        string calldata _seniorDepositTokenSymbol,
        bytes calldata _params
    ) external initializer {
        _setName(_seniorDepositTokenName);
        _setSymbol(_seniorDepositTokenSymbol);
        _setDecimals(_seniorDepositTokenDecimals);

        addressResolver = _addressResolver;
        underlyingAsset = _underlyingAsset;

        emit Initialized(
            _underlyingAsset,
            addressResolver.getAddress('liquidityManager'),
            _seniorDepositTokenDecimals,
            _seniorDepositTokenName,
            _seniorDepositTokenSymbol,
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
    ) external onlyAdmin returns (bool) {
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
     * @param _amount The amount being burned
     * @param _index The new liquidity index of the reserve
     **/
    function burn(
        address _user,
        uint256 _amount,
        uint256 _index
    ) external onlyAdmin {
        uint256 amountScaled = _amount.rayDiv(_index);
        require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
        _burn(_user, amountScaled);
        //IERC20(underlyingAsset).safeTransfer(_user, _amount);
        addWithdraw(_user, _amount);
        emit Transfer(_user, address(0), _amount);
        emit Burn(_user, _amount, _index);
    }

    function transferUnderlyingTo(address _target, uint256 _amount)
        external
        onlyAdmin
    {
        IERC20(underlyingAsset).safeTransfer(_target, _amount);
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the updated
     * stored balance divided by the reserve's liquidity index at the moment of the update
     * @param _user The user whose balance is calculated
     * @return THe scaled balance of the user
     **/
    function scaledBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param _user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address _user)
        public
        view
        override(BaseERC20)
        returns (uint256)
    {
        ILiquidityManagerProxy liquidityManagerProxy = getLiquidityManagerProxy();
        return
            super.balanceOf(_user).rayMul(
                liquidityManagerProxy.getReserveNormalizedIncome(
                    underlyingAsset,
                    ReserveLogic.Tranche.SENIOR
                )
            );
    }

    /**
     * @dev calculates the total supply of the specific junior deposit token
     * since the balance of every single user increases over time, the totally supply does that too.
     * @return the current total supply
     **/
    function totalSupply() public view override(BaseERC20) returns (uint256) {
        uint256 currentSupplyScaled = super.totalSupply();
        if (currentSupplyScaled == 0) {
            return 0;
        }
        ILiquidityManagerProxy liquidityManagerProxy = getLiquidityManagerProxy();

        return
            currentSupplyScaled.rayMul(
                liquidityManagerProxy.getReserveNormalizedIncome(
                    underlyingAsset,
                    ReserveLogic.Tranche.SENIOR
                )
            );
    }

    function scaledTotalSupply() public view returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev Return instance of ILiquidityManagerProxy
     **/
    function getLiquidityManagerProxy()
        internal
        view
        returns (ILiquidityManagerProxy)
    {
        address liquidityManagerProxyAddress = addressResolver.getAddress(
            'liquidityManagerProxy'
        );
        return ILiquidityManagerProxy(liquidityManagerProxyAddress);
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return SENIOR_DEPOSIT_TOKEN_REVISION;
    }
}

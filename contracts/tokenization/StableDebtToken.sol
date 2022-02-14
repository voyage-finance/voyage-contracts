// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/math/WadRayMath.sol';
import '../component/liquidity/LiquidityManager.sol';
import {MathUtils} from '../libraries/math/MathUtils.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import './base/BaseERC20.sol';

contract StableDebtToken is BaseERC20 {
    using WadRayMath for uint256;
    using SafeMath for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    uint256 internal _avgStableRate;
    mapping(address => uint40) internal _timestamps;
    mapping(address => uint256) internal _usersStableRate;
    mapping(address => mapping(address => uint256)) internal _borrowAllowances;
    uint40 internal _totalSupplyTimestamp;
    LiquidityManager private _liquidityManager;
    address internal _underlyingAsset;

    uint8 private _decimals;

    /**
     * @dev Emitted when an aToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated lending pool
     * @param aTokenDecimals the decimals of the underlying
     * @param aTokenName the name of the aToken
     * @param aTokenSymbol the symbol of the aToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        uint8 aTokenDecimals,
        string aTokenName,
        string aTokenSymbol,
        bytes params
    );

    modifier onlyLiquidityManager() {
        require(
            msg.sender == address(_liquidityManager),
            'The caller of this function must be liquidityManager'
        );
        _;
    }

    constructor(string memory debtTokenName, string memory debtTokenSymbol)
        BaseERC20(debtTokenName, debtTokenSymbol)
    {}

    /**
     * @dev Initializes the debt token.
     * @param lm The address of the liquidity manager where this vToken(JD&SD) will be used
     * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     */
    function initialize(
        LiquidityManager lm,
        address underlyingAsset,
        uint8 debtTokenDecimals,
        bytes calldata params
    ) public {
        _decimals = debtTokenDecimals;
        _liquidityManager = lm;
        _underlyingAsset = underlyingAsset;

        emit Initialized(
            underlyingAsset,
            address(lm),
            debtTokenDecimals,
            super.name(),
            super.symbol(),
            params
        );
    }

    /**
     * @dev Gets the revision of the stable debt token implementation
     * @return The debt token implementation revision
     **/
    function getRevision() internal pure virtual returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /**
     * @dev Returns the average stable rate across all the stable rate debt
     * @return the average stable rate
     **/
    function getAverageStableRate() external view virtual returns (uint256) {
        return _avgStableRate;
    }

    /**
     * @dev Returns the timestamp of the last user action
     * @return The last update timestamp
     **/
    function getUserLastUpdated(address user)
        external
        view
        virtual
        returns (uint40)
    {
        return _timestamps[user];
    }

    /**
     * @dev Returns the stable rate of the user
     * @param user The address of the user
     * @return The stable rate of user
     **/
    function getUserStableRate(address user)
        external
        view
        virtual
        returns (uint256)
    {
        return _usersStableRate[user];
    }

    /**
     * @dev Calculates the total supply
     * @param avgRate The average rate at which the total supply increases
     * @return The debt balance of the user since the last burn/mint action
     **/
    function _calcTotalSupply(uint256 avgRate)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 principalSupply = super.totalSupply();

        if (principalSupply == 0) {
            return 0;
        }

        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            avgRate,
            _totalSupplyTimestamp
        );

        return principalSupply.rayMul(cumulatedInterest);
    }

    /**
     * @dev Calculates the current user debt balance
     * @return The accumulated debt of the user
     **/
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 accountBalance = super.balanceOf(account);
        uint256 stableRate = _usersStableRate[account];
        if (accountBalance == 0) {
            return 0;
        }
        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            stableRate,
            _timestamps[account]
        );
        return accountBalance.rayMul(cumulatedInterest);
    }

    struct MintLocalVars {
        uint256 previousSupply;
        uint256 nextSupply;
        uint256 amountInRay;
        uint256 newStableRate;
        uint256 currentAvgStableRate;
    }

    function _decreaseBorrowAllowance(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal {
        uint256 newAllowance = _borrowAllowances[delegator][delegatee].sub(
            amount,
            Errors.BORROW_ALLOWANCE_NOT_ENOUGH
        );

        _borrowAllowances[delegator][delegatee] = newAllowance;
    }

    /**
     * @dev Calculates the increase in balance since the last user interaction
     * @param user The address of the user for which the interest is being accumulated
     * @return The previous principal balance, the new principal balance and the balance increase
     **/
    function _calculateBalanceIncrease(address user)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 previousPrincipalBalance = super.balanceOf(user);

        if (previousPrincipalBalance == 0) {
            return (0, 0, 0);
        }

        // Calculation of the accrued interest since the last accumulation
        uint256 balanceIncrease = balanceOf(user).sub(previousPrincipalBalance);

        return (
            previousPrincipalBalance,
            previousPrincipalBalance.add(balanceIncrease),
            balanceIncrease
        );
    }

    /**
     * @dev Mints debt token to the `onBehalfOf` address.
     * -  Only callable by the LendingPool
     * - The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt tokens to mint
     * @param rate The rate of the debt being minted
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 rate
    ) external onlyLiquidityManager returns (bool) {
        MintLocalVars memory vars;

        if (user != onBehalfOf) {
            _decreaseBorrowAllowance(onBehalfOf, user, amount);
        }

        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(onBehalfOf);

        vars.previousSupply = totalSupply();
        vars.currentAvgStableRate = _avgStableRate;
        vars.nextSupply = _totalSupply = vars.previousSupply.add(amount);

        vars.amountInRay = amount.wadToRay();

        vars.newStableRate = _usersStableRate[onBehalfOf]
            .rayMul(currentBalance.wadToRay())
            .add(vars.amountInRay.rayMul(rate))
            .rayDiv(currentBalance.add(amount).wadToRay());

        require(
            vars.newStableRate <= type(uint128).max,
            Errors.SDT_STABLE_DEBT_OVERFLOW
        );
        _usersStableRate[onBehalfOf] = vars.newStableRate;

        //solium-disable-next-line
        _totalSupplyTimestamp = _timestamps[onBehalfOf] = uint40(
            block.timestamp
        );

        // Calculates the updated average stable rate
        vars.currentAvgStableRate = _avgStableRate = vars
            .currentAvgStableRate
            .rayMul(vars.previousSupply.wadToRay())
            .add(rate.rayMul(vars.amountInRay))
            .rayDiv(vars.nextSupply.wadToRay());

        _mint(onBehalfOf, amount.add(balanceIncrease));
        return currentBalance == 0;
    }

    /**
     * @dev Returns the total supply
     **/
    function totalSupply() public view override returns (uint256) {
        return _calcTotalSupply(_avgStableRate);
    }
}

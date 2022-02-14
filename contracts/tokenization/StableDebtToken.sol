// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../libraries/math/WadRayMath.sol';
import '../component/liquidity/LiquidityManager.sol';

contract StableDebtToken is ERC20 {
    using WadRayMath for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    uint256 internal _avgStableRate;
    mapping(address => uint40) internal _timestamps;
    mapping(address => uint256) internal _usersStableRate;
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

    constructor(string memory debtTokenName, string memory debtTokenSymbol)
        ERC20(debtTokenName, debtTokenSymbol)
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
}

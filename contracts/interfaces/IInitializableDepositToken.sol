// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**
 * @title IDepositToken
 * @notice Interface for the initialize function on JuniorDepositToken and SeniorDepositToken
 **/
interface IInitializableDepositToken {
    /**
     * @dev Emitted when an depositToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param liquidityManagerProxy The address of the associated liquidity manager proxy
     * @param tokenDecimals the decimals of the underlying
     * @param tokenName the name of the depositToken
     * @param tokenSymbol the symbol of the depositToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed liquidityManagerProxy,
        uint8 tokenDecimals,
        string tokenName,
        string tokenSymbol,
        bytes params
    );

    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 index
    );
}

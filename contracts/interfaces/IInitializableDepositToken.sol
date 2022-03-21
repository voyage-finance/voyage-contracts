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
}

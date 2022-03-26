// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param debtTokenDecimals the decimals of the debt token
     * @param debtTokenName the name of the debt token
     * @param debtTokenSymbol the symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @dev Returns the average rate of all the stable rate loans.
     * @return The average stable rate
     **/
    function getAverageStableRate() external view returns (uint256);

    /**
     * @dev Returns the total supply and the average stable rate
     **/
    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256);
}

library CoreLibrary {
     enum Tranche { JUNIOR, SENIOR }

    struct ReserveData {
        //the liquidity index. Expressed in ray
        uint256 lastLiquidityCumulativeIndex;
        //the current supply rate. Expressed in ray
        uint256 currentLiquidityRate;
        //the total borrows of the reserve at a stable rate. Expressed in the currency decimals
        uint256 totalBorrows;
        //the decimals of the reserve asset
        uint256 decimals;
        /**
        * @dev address of the aToken representing the asset
        **/
        address oTokenAddress;
        /**
        * @dev address of the interest rate strategy contract
        **/
        address interestRateStrategyAddress;
        uint40 lastUpdateTimestamp;
        // isActive = true means the reserve has been activated and properly configured
        bool isActive;
        Tranche tranche;
    }
}
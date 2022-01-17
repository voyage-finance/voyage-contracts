// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.9;

import "./math/WadRayMath.sol";

library CoreLibrary {
    using SafeMath for uint256;
    using WadRayMath for uint256;


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

    function init(
        ReserveData storage _self,
        address _oTokenAddress,
        uint256 _decimals,
        address _interestRateStrategyAddress,
        Tranche _tranche
    ) external {
        require(_self.oTokenAddress == address(0), "Reserve has already been initialized");
        if (_self.lastLiquidityCumulativeIndex == 0) {
            _self.lastLiquidityCumulativeIndex = WadRayMath.ray();
        }

         _self.oTokenAddress = _oTokenAddress;
        _self.decimals = _decimals;

        _self.interestRateStrategyAddress = _interestRateStrategyAddress;
        _self.tranche = _tranche;
        _self.isActive = true;
    }
}
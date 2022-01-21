// SPDX-License-Identifier: GPL-3.0
pragma solidity  ^0.8.9;

import "./math/WadRayMath.sol";

library CoreLibrary {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant SECONDS_PER_YEAR = 365 days;


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



    /**
    * @dev returns the ongoing normalized income for the reserve.
    * a value of 1e27 means there is no income. As time passes, the income is accrued.
    * A value of 2*1e27 means that the income of the reserve is double the initial amount.
    * @param _reserve the reserve object
    * @return the normalized income. expressed in ray
    **/
    function getNormalizedIncome(CoreLibrary.ReserveData storage _reserve)
        internal
        view
        returns (uint256)
    {
        uint256 cumulated = calculateLinearInterest(
            _reserve
                .currentLiquidityRate,
            _reserve
                .lastUpdateTimestamp
        )
            .rayMul(_reserve.lastLiquidityCumulativeIndex);

        return cumulated;

    }

    function calculateLinearInterest(
        uint256 _rate,
        uint40 _lastUpdateTimestamp
    )
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp.sub(uint256(_lastUpdateTimestamp));

        uint256 timeDelta = timeDifference.wadToRay().rayDiv(SECONDS_PER_YEAR.wadToRay());

        return _rate.rayMul(timeDelta).add(WadRayMath.ray());
    }

    /**
    * @dev Updates the liquidity cumulative index Ci
    * @param _self the reserve object
    **/
    function updateCumulativeIndexes(ReserveData storage _self) internal {
        uint256 totalBorrows = getTotalBorrows(_self);

        if (totalBorrows > 0) {
            //only cumulating if there is any income being produced
            uint256 cumulatedLiquidityInterest = calculateLinearInterest(
                _self.currentLiquidityRate,
                _self.lastUpdateTimestamp
            );

            _self.lastLiquidityCumulativeIndex = cumulatedLiquidityInterest.rayMul(
                _self.lastLiquidityCumulativeIndex
            );
        }
    }

    /**
    * @dev returns the total borrows on the reserve
    * @param _reserve the reserve object
    * @return the total borrows (stable + variable)
    **/
    function getTotalBorrows(CoreLibrary.ReserveData storage _reserve)
        internal
        view
        returns (uint256)
    {
        return _reserve.totalBorrows;
    }


}
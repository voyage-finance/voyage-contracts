// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import './math/WadRayMath.sol';

library CoreLibrary {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    enum Tranche {
        JUNIOR,
        SENIOR
    }

    struct ReserveConfigurationMap {
        //bit 0-15: Liq. bonus
        //bit 16-23: Decimals
        //bit 24: Reserve is active
        //bit 25: reserve is frozen
        //bit 26: borrowing is enabled
        //bit 27-30: reserved
        //bit 31-46: reserve factor
        //bit 47-62: lock up period in seconds
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap config;
        // for calculating overall interested accumulated
        // then split it into two indexs base on two allocations
        uint256 currentOverallLiquidityRate;
        // Expressed in ray
        uint256 currentSeniorIncomeAllocation;
        // Expressed in ray
        uint256 currentJuniorIncomeAllocation;
        uint256 currentJuniorLiquidityIndex;
        uint256 currentSeniorLiquidityIndex;
        uint256 totalBorrows;
        uint256 currentBorrowRate;
        //the decimals of the reserve asset
        uint256 decimals;
        address interestRateStrategyAddress;
        address vTokenAddress;
        uint40 lastUpdateTimestamp;
    }

    // use a mapping mapping(address => Deposit[]) to track amount that can be withdrawn
    // not sure if this should in the vToken contract
    struct Deposit {
        Tranche tranche;
        uint256 startDate;
        uint256 lockFor;
        uint256 amount;
    }

    // struct ReserveData {
    //     //the liquidity index. Expressed in ray
    //     uint256 lastLiquidityCumulativeIndex;
    //     //the current supply rate. Expressed in ray
    //     uint256 currentLiquidityRate;
    //     //the total borrows of the reserve at a stable rate. Expressed in the currency decimals
    //     uint256 totalBorrows;
    //     //the decimals of the reserve asset
    //     uint256 decimals;
    //     /**
    //     * @dev address of the aToken representing the asset
    //     **/
    //     address oTokenAddress;
    //     /**
    //     * @dev address of the interest rate strategy contract
    //     **/
    //     address interestRateStrategyAddress;
    //     uint40 lastUpdateTimestamp;
    //     // isActive = true means the reserve has been activated and properly configured
    //     bool isActive;
    //     Tranche tranche;
    // }

    function init(
        ReserveData storage _self,
        address _vTokenAddress,
        uint256 _decimals,
        address _interestRateStrategyAddress
    ) external {
        require(
            _self.vTokenAddress == address(0),
            'Reserve has already been initialized'
        );
        if (_self.currentSeniorLiquidityIndex == 0) {
            _self.currentSeniorLiquidityIndex = WadRayMath.ray();
        }

        if (_self.currentJuniorLiquidityIndex == 0) {
            _self.currentJuniorLiquidityIndex = WadRayMath.ray();
        }

        _self.vTokenAddress = _vTokenAddress;
        _self.decimals = _decimals;

        _self.interestRateStrategyAddress = _interestRateStrategyAddress;
    }

    /**
     * @dev returns the ongoing normalized income for the reserve.
     * a value of 1e27 means there is no income. As time passes, the income is accrued.
     * A value of 2*1e27 means that the income of the reserve is double the initial amount.
     * @param _reserve the reserve object
     * @param _tranche the tranche of the reserve
     * @return the normalized income. expressed in ray
     **/
    function getNormalizedIncome(
        CoreLibrary.ReserveData storage _reserve,
        Tranche _tranche
    ) internal view returns (uint256) {
        uint256 liquidityRate;
        uint256 cumulated;
        // e.g.
        // junior: 1 * 1e27
        // senior: 9 * 1e27
        // total: 10 * 1e27
        // ratio (for junior): 0.1 * 1e27
        uint256 totalAllocation = _reserve.currentJuniorIncomeAllocation.add(
            _reserve.currentSeniorIncomeAllocation
        );

        if (_tranche == Tranche.JUNIOR) {
            liquidityRate = _reserve.currentOverallLiquidityRate.rayMul(
                _reserve.currentJuniorIncomeAllocation.div(totalAllocation)
            );
            return
                calculateLinearInterest(
                    liquidityRate,
                    _reserve.lastUpdateTimestamp
                ).rayMul(_reserve.currentJuniorLiquidityIndex);
        } else {
            liquidityRate = _reserve.currentOverallLiquidityRate.rayMul(
                _reserve.currentSeniorIncomeAllocation.div(totalAllocation)
            );
            return
                calculateLinearInterest(
                    liquidityRate,
                    _reserve.lastUpdateTimestamp
                ).rayMul(_reserve.currentSeniorLiquidityIndex);
        }
    }

    function calculateLinearInterest(uint256 _rate, uint40 _lastUpdateTimestamp)
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 timeDifference = block.timestamp.sub(
            uint256(_lastUpdateTimestamp)
        );

        uint256 timeDelta = timeDifference.wadToRay().rayDiv(
            SECONDS_PER_YEAR.wadToRay()
        );

        return _rate.rayMul(timeDelta).add(WadRayMath.ray());
    }

    /**
     * @dev Updates the liquidity cumulative index Ci
     * @param _self the reserve object
     * @param _tranche the tranche of the reserve
     **/
    function updateCumulativeIndexes(
        ReserveData storage _self,
        Tranche _tranche
    ) internal {
        uint256 totalBorrows = getTotalBorrows(_self);

        if (totalBorrows <= 0) {
            return;
        }

        uint256 liquidityRate;
        uint256 cumulated;
        uint256 totalAllocation = _self.currentJuniorIncomeAllocation.add(
            _self.currentSeniorIncomeAllocation
        );

        if (_tranche == Tranche.JUNIOR) {
            liquidityRate = _self.currentOverallLiquidityRate.rayMul(
                _self.currentJuniorIncomeAllocation.div(totalAllocation)
            );
            uint256 cumulatedLiquidityInterest = calculateLinearInterest(
                liquidityRate,
                _self.lastUpdateTimestamp
            ).rayMul(_self.currentJuniorLiquidityIndex);
            _self.currentJuniorLiquidityIndex = cumulatedLiquidityInterest
                .rayMul(_self.currentJuniorLiquidityIndex);
        } else {
            liquidityRate = _self.currentOverallLiquidityRate.rayMul(
                _self.currentSeniorIncomeAllocation.div(totalAllocation)
            );
            uint256 cumulatedLiquidityInterest = calculateLinearInterest(
                liquidityRate,
                _self.lastUpdateTimestamp
            ).rayMul(_self.currentSeniorLiquidityIndex);
            _self.currentSeniorLiquidityIndex = cumulatedLiquidityInterest
                .rayMul(_self.currentSeniorLiquidityIndex);
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

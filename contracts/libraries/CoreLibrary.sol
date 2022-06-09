// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {WadRayMath} from "./math/WadRayMath.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
        uint256 totalBorrows;
        uint256 currentBorrowRate;
        // Expressed in ray
        uint256 securityRequirement;
        //the decimals of the reserve asset
        uint256 decimals;
        address interestRateStrategyAddress;
        address jdTokenAddress;
        address sdTokenAddress;
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

    function init(
        ReserveData storage _self,
        address _jdTokenAddress,
        address _sdTokenAddress,
        uint256 _decimals,
        address _interestRateStrategyAddress,
        uint256 _securityRequirement
    ) external {
        require(
            _self.jdTokenAddress == address(0),
            "Reserve has already been initialized"
        );
        _self.jdTokenAddress = _jdTokenAddress;
        _self.sdTokenAddress = _sdTokenAddress;
        _self.decimals = _decimals;

        _self.securityRequirement = _securityRequirement;
        _self.interestRateStrategyAddress = _interestRateStrategyAddress;
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

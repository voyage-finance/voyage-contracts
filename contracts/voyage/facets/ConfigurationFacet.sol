// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {LibAppStorage, Storage, ReserveConfigurationMap} from "../libraries/LibAppStorage.sol";
import {LibReserveConfiguration} from "../libraries/LibReserveConfiguration.sol";
import {LibVault} from "../libraries/LibVault.sol";

contract ConfigurationFacet is Storage, ReentrancyGuard {
    using LibReserveConfiguration for ReserveConfigurationMap;
    /* --------------------------------- events --------------------------------- */
    event LiquidationConfigurationUpdated(
        address indexed _asset,
        uint256 _liquidationBonus
    );
    event IncomeRatioUpdated(address indexed _asset, uint256 _incomeRatio);
    event MarginParametersUpdated(
        address indexed _asset,
        uint256 _min,
        uint256 _max,
        uint256 _marginRequirement
    );
    event LoanParametersUpdated(
        address indexed _asset,
        uint256 _epoch,
        uint256 _term,
        uint256 _gracePeriod
    );

    /* --------------------------------- errors --------------------------------- */
    error IllegalLoanParameters();
    error IllegalMarginParameters();

    /// @dev maximum size of _liquidationBonus is 2^16, ~600%
    /// @param _asset address of the underlying ERC20
    /// @param _liquidationBonus liquidation bonus, percentage expressed as basis points
    function setLiquidationBonus(address _asset, uint256 _liquidationBonus)
        external
        authorised
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_asset);
        conf.setLiquidationBonus(_liquidationBonus);
        LibReserveConfiguration.saveConfiguration(_asset, conf);
        emit LiquidationConfigurationUpdated(_asset, _liquidationBonus);
    }

    function setIncomeRatio(address _asset, uint256 _ratio)
        external
        authorised
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_asset);
        conf.setIncomeRatio(_ratio);
        LibReserveConfiguration.saveConfiguration(_asset, conf);
        emit IncomeRatioUpdated(_asset, _ratio);
    }

    function setLoanParams(
        address _asset,
        uint256 _epoch,
        uint256 _term,
        uint256 _gracePeriod
    ) external authorised {
        if (_epoch > _term) {
            revert IllegalLoanParameters();
        }
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_asset);
        conf.setLoanInterval(_epoch);
        conf.setLoanTerm(_term);
        conf.setGracePeriod(_gracePeriod);
        LibReserveConfiguration.saveConfiguration(_asset, conf);
        emit LoanParametersUpdated(_asset, _epoch, _term, _gracePeriod);
    }

    function setMarginParams(
        address _asset,
        uint256 _min,
        uint256 _max,
        uint256 _marginRequirement
    ) external authorised {
        if (_min > _max || _marginRequirement == 0) {
            revert IllegalMarginParameters();
        }
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_asset);
        conf.setMinMargin(_min);
        conf.setMaxMargin(_max);
        conf.setMarginRequirement(_marginRequirement);
        LibReserveConfiguration.saveConfiguration(_asset, conf);
        emit MarginParametersUpdated(_asset, _min, _max, _marginRequirement);
    }
}

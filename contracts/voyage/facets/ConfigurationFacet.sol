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
        address indexed _collection,
        uint256 _liquidationBonus
    );
    event IncomeRatioUpdated(address indexed _collection, uint256 _incomeRatio);
    event LoanParametersUpdated(
        address indexed _collection,
        uint256 _epoch,
        uint256 _term,
        uint256 _gracePeriod
    );

    /* --------------------------------- errors --------------------------------- */
    error IllegalLoanParameters();

    /// @dev maximum size of _liquidationBonus is 2^16, ~600%
    /// @param _collection address of the underlying NFT collection
    /// @param _liquidationBonus liquidation bonus, percentage expressed as basis points
    function setLiquidationBonus(address _collection, uint256 _liquidationBonus)
        external
        authorised
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        conf.setLiquidationBonus(_liquidationBonus);
        LibReserveConfiguration.saveConfiguration(_collection, conf);
        emit LiquidationConfigurationUpdated(_collection, _liquidationBonus);
    }

    function setIncomeRatio(address _collection, uint256 _ratio)
        external
        authorised
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        conf.setIncomeRatio(_ratio);
        LibReserveConfiguration.saveConfiguration(_collection, conf);
        emit IncomeRatioUpdated(_collection, _ratio);
    }

    function setLoanParams(
        address _collection,
        uint256 _epoch,
        uint256 _term,
        uint256 _gracePeriod
    ) external authorised {
        if (_epoch > _term) {
            revert IllegalLoanParameters();
        }
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        conf.setLoanInterval(_epoch);
        conf.setLoanTerm(_term);
        conf.setGracePeriod(_gracePeriod);
        LibReserveConfiguration.saveConfiguration(_collection, conf);
        emit LoanParametersUpdated(_collection, _epoch, _term, _gracePeriod);
    }
}

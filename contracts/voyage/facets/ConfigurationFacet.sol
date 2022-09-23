// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPaymaster} from "@opengsn/contracts/src/BasePaymaster.sol";
import {LibAppStorage, AppStorage, Storage, ReserveConfigurationMap} from "../libraries/LibAppStorage.sol";
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
    event OptimalLiquidityRatioUpdated(
        address indexed _collection,
        uint256 _optimalRatio
    );
    event MaxTwapStaleness(
        address indexed _collection,
        uint256 _maxTwapStaleness
    );
    event LoanParametersUpdated(
        address indexed _collection,
        uint256 _epoch,
        uint256 _term,
        uint256 _gracePeriod
    );
    event GSNConfigurationUpdated(
        address _paymaster,
        address _trustedForwarder
    );
    event MarketplaceAdapterUpdated(
        address indexed _marketplace,
        address _strategy
    );

    /* --------------------------------- errors --------------------------------- */
    error IllegalLoanParameters();
    error InvalidGSNConfiguration();

    /* --------------------------------- setters -------------------------------- */

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

    function setOptimalLiquidityRatio(address _collection, uint256 _ratio)
        external
        authorised
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        conf.setOptimalLiquidityRatio(_ratio);
        LibReserveConfiguration.saveConfiguration(_collection, conf);
        emit OptimalLiquidityRatioUpdated(_collection, _ratio);
    }

    function setMaxTwapStaleness(address _collection, uint256 _maxTwapStaleness)
        external
        authorised
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        conf.setMaxTwapStaleness(_maxTwapStaleness);
        LibReserveConfiguration.saveConfiguration(_collection, conf);
        emit MaxTwapStaleness(_collection, _maxTwapStaleness);
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

    /// @dev Sets the Voyage paymaster
    /// @param _paymaster the address of the paymaster contract.
    /// @param _trustedForwarder the address of the GSN forwarder contract. Deployed by GSN.
    function setGSNConfiguration(address _paymaster, address _trustedForwarder)
        external
        authorised
    {
        if (_paymaster == address(0) || !Address.isContract(_paymaster)) {
            revert InvalidGSNConfiguration();
        }

        if (
            _trustedForwarder == address(0) ||
            _trustedForwarder != IPaymaster(_paymaster).trustedForwarder()
        ) {
            revert InvalidGSNConfiguration();
        }

        AppStorage storage s = LibAppStorage.ds();
        s.paymaster = _paymaster;
        s.trustedForwarder = _trustedForwarder;
        emit GSNConfigurationUpdated(_paymaster, _trustedForwarder);
    }

    function getPaymasterAddr() external view returns (address) {
        return LibAppStorage.ds().paymaster;
    }

    function updateMarketPlaceData(address _marketplace, address _strategy)
        external
        authorised
    {
        LibAppStorage
            .ds()
            .marketPlaceData[_marketplace]
            .adapterAddr = _strategy;
        emit MarketplaceAdapterUpdated(_marketplace, _strategy);
    }

    function upgradeJuniorDepositTokenImpl(address _impl) external authorised {
        LibAppStorage.ds().juniorDepositTokenBeacon.upgradeTo(_impl);
    }

    function upgradeSeniorDepositTokenImpl(address _impl) external authorised {
        LibAppStorage.ds().seniorDepositTokenBeacon.upgradeTo(_impl);
    }

    function getIncomeRatio(address _collection) public view returns (uint256) {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        return conf.getIncomeRatio();
    }

    function getMaxTwapStaleness(address _collection)
        public
        view
        returns (uint256)
    {
        ReserveConfigurationMap memory conf = LibReserveConfiguration
            .getConfiguration(_collection);
        return conf.getMaxTwapStaleness();
    }
}

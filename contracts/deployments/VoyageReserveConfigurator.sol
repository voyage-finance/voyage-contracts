// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILiquidityFacet} from "../voyage/interfaces/ILiquidityFacet.sol";
import {ConfigurationFacet} from "../voyage/facets/ConfigurationFacet.sol";

struct ConfigureReserveInput {
    address collection;
    address currency;
    address interestRateStrategyAddress;
    address priceOracle;
    uint256 liquidationBonus;
    uint256 incomeRatio;
    uint256 optimalLiquidityRatio;
    uint256 maxTwapStaleness;
    uint256 epoch;
    uint256 term;
    uint256 gracePeriod;
    address treasury;
    uint40 protocolFee;
    address[] marketplaces;
    address[] adapters;
}

contract VoyageReserveConfigurator is Ownable {
    address public voyage;

    constructor(address _voyage) {
        voyage = _voyage;
    }

    function initReserves(ConfigureReserveInput[] calldata input)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < input.length; i++) {
            _initReserve(input[i]);
        }
    }

    function initReserve(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ILiquidityFacet(voyage).initReserve(
            input.collection,
            input.currency,
            input.interestRateStrategyAddress,
            input.priceOracle
        );
    }

    function activateReserve(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ILiquidityFacet(voyage).activateReserve(input.collection);
    }

    function deactivateReserve(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ILiquidityFacet(voyage).deactivateReserve(input.collection);
    }

    function upgradePriceOracleImpl(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ILiquidityFacet(voyage).upgradePriceOracleImpl(
            input.collection,
            input.priceOracle
        );
    }

    function updateProtocolFee(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ILiquidityFacet(voyage).updateProtocolFee(
            input.treasury,
            input.protocolFee
        );
    }

    function updateWETH9(address weth9) public onlyOwner {
        ILiquidityFacet(voyage).updateWETH9(weth9);
    }

    function setLoanParams(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ConfigurationFacet(voyage).setLoanParams(
            input.collection,
            input.epoch,
            input.term,
            input.gracePeriod
        );
    }

    function setLiquidationBonus(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ConfigurationFacet(voyage).setLiquidationBonus(
            input.collection,
            input.liquidationBonus
        );
    }

    function setIncomeRatio(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ConfigurationFacet(voyage).setIncomeRatio(
            input.collection,
            input.incomeRatio
        );
    }

    function setOptimalLiquidityRatio(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ConfigurationFacet(voyage).setOptimalLiquidityRatio(
            input.collection,
            input.optimalLiquidityRatio
        );
    }

    function setMaxTwapStaleness(ConfigureReserveInput calldata input)
        public
        onlyOwner
    {
        ConfigurationFacet(voyage).setMaxTwapStaleness(
            input.collection,
            input.maxTwapStaleness
        );
    }

    function updateMarketPlaceData(address marketplace, address adapter)
        public
        onlyOwner
    {
        ConfigurationFacet(voyage).updateMarketPlaceData(marketplace, adapter);
    }

    function setGSNConfiguration(address paymaster, address trustedForwarder)
        public
        onlyOwner
    {
        ConfigurationFacet(voyage).setGSNConfiguration(
            paymaster,
            trustedForwarder
        );
    }

    function upgradeJuniorDepositTokenImpl(address _impl) public onlyOwner {
        ConfigurationFacet(voyage).upgradeJuniorDepositTokenImpl(_impl);
    }

    function upgradeSeniorDepositTokenImpl(address _impl) public onlyOwner {
        ConfigurationFacet(voyage).upgradeSeniorDepositTokenImpl(_impl);
    }

    function _initReserve(ConfigureReserveInput calldata input) internal {
        initReserve(input);
        activateReserve(input);
        updateProtocolFee(input);
        setLiquidationBonus(input);
        setIncomeRatio(input);
        setOptimalLiquidityRatio(input);
        setMaxTwapStaleness(input);
        setLoanParams(input);
        for (uint256 i = 0; i < input.marketplaces.length; i++) {
            updateMarketPlaceData(input.marketplaces[i], input.adapters[i]);
        }
    }
}

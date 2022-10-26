// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import {Setup} from "./utils/Setup.sol";
import {Voyage} from "../../contracts/voyage/Voyage.sol";
import {Crab} from "../../contracts/mock/Crab.sol";
import {DefaultReserveInterestRateStrategy} from "../../contracts/voyage/strategy/DefaultReserveInterestRateStrategy.sol";
import {PriceOracle} from "../../contracts/voyage/infra/PriceOracle.sol";
import {ILiquidityFacet} from "../../contracts/voyage/interfaces/ILiquidityFacet.sol";

contract LiquidityFacetTest is Test {
    Crab crab;
    DefaultReserveInterestRateStrategy defaultReserveInterestRateStrategy;
    PriceOracle priceOracle;
    address voyage;
    address weth;

    function setUp() public {
        console.log("LiquidityFacetTest address: ", address(this));
        (voyage, weth) = Setup.initFacets(address(this));
        crab = new Crab("Crab", "Crab");
        defaultReserveInterestRateStrategy = new DefaultReserveInterestRateStrategy(
            (8 * 10e28) / 10,
            (4 * 10e27) / 100,
            (2 * 10e27) / 10
        );
        priceOracle = new PriceOracle();
    }

    function testInitReserve() public {
        (bool initialized, bool activated) = ILiquidityFacet(voyage)
            .getReserveStatus(address(crab));
        assertTrue(!initialized);
        assertTrue(!activated);

        ILiquidityFacet(voyage).initReserve(
            address(crab),
            weth,
            address(defaultReserveInterestRateStrategy),
            address(priceOracle)
        );
        (bool initializedAfter, bool activatedAfter) = ILiquidityFacet(voyage)
            .getReserveStatus(address(crab));
        assertTrue(initializedAfter);
        assertTrue(!activated);
    }
}

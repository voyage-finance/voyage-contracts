pragma solidity 0.8.9;

import TestWrapper from "test/pnm/TestWrapper.t.sol";
import "./TestWrapper.t.sol";

contract TestCredit is TestWrapper {
    function setUp() public {
        deploy();
    }

    function check() public {
        priceOracle.updateTwap(crab, 3.1415926);
        require(
            PriceOracle.getTwap(crab) == 3.1415926,
            "[!!!] Invariant violation: only owner or operator is able to update price."
        );
    }
}

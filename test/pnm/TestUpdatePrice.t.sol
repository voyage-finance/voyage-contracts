pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestCredit is TestBase {
    function setUp() public {
        deploy();
    }

    function check() public {
        priceOracle.updateTwap(crab, 31415926);
        require(
            priceOracle.getTwap(crab) == 31415926,
            "[!!!] Invariant violation: only owner or operator is able to update price."
        );
    }
}

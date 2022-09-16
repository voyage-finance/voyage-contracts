pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestCredit is TestBase {
    function setUp() public {
        deploy();
    }

    function check() public override {
        priceOracle.updateTwap(address(crab), 31415926);
        (uint price, ) = priceOracle.getTwap(address(crab));
        require(
            price == 31415926,
            "[!!!] Invariant violation: only owner or operator is able to update price."
        );
    }
}

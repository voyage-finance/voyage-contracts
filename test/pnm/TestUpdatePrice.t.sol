pragma solidity 0.8.9;

import TestWrapper from "test/pnm/TestWrapper.t.sol";
import "./TestWrapper.t.sol";

contract TestCredit is TestWrapper {
    function setUp() public {
        deploy();
    }

    function check() public {
        require(
            priceOracle
            .updateTwap(
                crab.address,
                1,
        ),
        "[!!!] Invariant violation: owner should be able to update price.",
        );
    }
}

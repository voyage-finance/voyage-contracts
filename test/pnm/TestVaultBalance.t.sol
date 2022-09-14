pragma solidity 0.8.9;

import TestWrapper from "test/pnm/TestWrapper.t.sol";
import "./TestWrapper.t.sol";

contract TestCredit is TestWrapper {
    function setUp() public {
        deploy();
    }

    function check() public {
        require(
            voyage
            .buyNow(
                crab.address,
                crab,
                vault,
                marketplace.address,
                ""
        ).to.be.revertedWithCustomError(voyage, 'InsufficientCash'),
        "[!!!] Invariant violation: buyNow should be fail if vault balance is 0.",
        );
    }
}

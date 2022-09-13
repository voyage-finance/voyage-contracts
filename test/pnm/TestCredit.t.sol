pragma solidity 0.8.9;

import TestWrapper from "test/pnm/TestWrapper.t.sol";

contract TestCredit is TestWrapper {
    function setUp() public {
        deploy();

        // set my credit limit to 0
    }

    function check() public {
        // call buyNow with 0 credit limit
        // check that it fails
    }
}
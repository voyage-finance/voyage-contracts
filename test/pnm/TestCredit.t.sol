pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestCredit is TestBase {
    function setUp() public {
        deploy();

        // set my credit limit to 0
    }

    function check() public override {
        // call buyNow with 0 credit limit
        // check that it fails
    }
}
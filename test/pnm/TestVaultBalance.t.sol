pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestVaultBalance is TestBase {
    function setUp() public {
        deploy();
    }

    function check() public override {
        require(
            voyage.buyNow(
                address(crab),
                1,
                vault,
                address(mockMarketPlace),
                ""
            ).to.be.revertedWithCustomError(voyage, "InsufficientCash"),
        "[!!!] Invariant violation: buyNow should be fail if vault balance is 0."
        );
    }
}

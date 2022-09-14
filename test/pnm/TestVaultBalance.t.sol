pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestVaultBalance is TestBase {
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
        "[!!!] Invariant violation: buyNow should be fail if vault balance is 0."
        );
    }
}

pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestVaultBalance is TestBase {
    function setUp() public {
        deploy();
    }

    function check() public override {
        (bool success,) = address(voyage).call(
            abi.encodeWithSignature("buyNow(address,uint256,address,address,bytes)", 
            address(crab),
            1,
            address(vault),
            address(mockMarketPlace),
            ""
        ));
        require(
            success == false,
            "[!!!] Invariant violation: buyNow should be fail if vault balance is 0."
        );
    }
}

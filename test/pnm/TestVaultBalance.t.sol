pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestVaultBalance is TestBase {
    function setUp() public {
        deploy();
    }

    function check() public override {
        (bool success,) = address(voyage).call(abi.encodeWithSignature("buyNow(address _collection, uint256 _tokenId, address payable _vault, address _marketplace, bytes calldata _data)", address(crab),
            1,
            vault,
            address(mockMarketPlace),
            ""));
        require(
            success == false,
        "[!!!] Invariant violation: buyNow should be fail if vault balance is 0."
        );
    }
}

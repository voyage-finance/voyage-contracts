pragma solidity 0.8.9;

import "./TestBase.t.sol";

contract TestUpdatePrice is TestBase {
    function setUp() public {
        deploy();
        setupTest();
    }

    function invariantUpdatePrice() public {
        vm.prank(agent);
        (bool success,) = address(priceOracle).call(
            abi.encodeWithSignature("updateTwap(address,uint256)", address(crab), 42 wei)
        );
        assert(success == false);
    }
}

pragma solidity ^0.8.9;

import "./TestBase.t.sol";

// This is a testing of the vault used by Voyage.
contract TestSeniorDepositToken is TestBase {
    // Shared setUp() process in TestBase

    function check() public {
        // Unbonding assets are the assets that are requested to be withdrawn and thus frozen.
        // The amount of unbounding assets should never be larger than the actual assets stored in the vault. 
        require(seniorDepositToken.totalUnbondingAsset() <= seniorDepositToken.totalAssets());
    }
}
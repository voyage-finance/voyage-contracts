pragma solidity ^0.8.9;

import { TestWrapper } from "test/pnm/TestWrapper.t.sol";

contract TestDepositInvariants is TestWrapper {
  uint juniorAmount = 1 * 10 ** 18;
  uint seniorAmount = 2 * 10 ** 18;

  function setUp() public {
    deploy();

    voyage.deposit(crab.address, 0, juniorAmount);
    voyage.deposit(crab.address, 1, seniorAmount);
  }

  function check() public override {
    uint juniorTokenBalance = juniorDepositToken.balanceOf(owner);
    uint seniorTokenBalance = seniorDepositToken.balanceOf(owner);

    require(
      juniorTokenBalance == juniorAmount,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: junior token balance (",
          Strings.toString(juniorTokenBalance),
          ") differs from deposited amount (",
          Strings.toString(juniorAmount),
          ")"
        )
      )
    );
    require(
      seniorTokenBalance == seniorAmount,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: senior token balance (",
          Strings.toString(seniorTokenBalance),
          ") differs from deposited amount (",
          Strings.toString(seniorAmount),
          ")"
        )
      )
    );

    
    uint maxWithdrawJuniorTokenAmount = juniorDepositToken.maxWithdraw(owner);
    uint maxWithdrawSeniorTokenAmount = seniorDepositToken.maxWithdraw(owner);

    require(
      maxWithdrawJuniorTokenAmount == juniorAmount,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: junior token max withdraw (",
          Strings.toString(maxWithdrawJuniorTokenAmount),
          ") differs from deposited amount (",
          Strings.toString(juniorAmount),
          ")"
        )
      )
    );
    require(
      maxWithdrawSeniorTokenAmount == seniorAmount,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: senior token max withdraw (",
          Strings.toString(maxWithdrawSeniorTokenAmount),
          ") differs from deposited amount (",
          Strings.toString(seniorAmount),
          ")"
        )
      )
    );

    uint totalAssetJunior = juniorDepositToken.totalAssets();
    uint totalAssetSenior = seniorDepositToken.totalAssets();

    require(
      totalAssetJunior == juniorAmount,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: junior token total asset (",
          Strings.toString(totalAssetJunior),
          ") differs from deposited amount (",
          Strings.toString(juniorAmount),
          ")"
        )
      )
    );
    require(
      totalAssetSenior == seniorAmount,
      string(
        abi.encodePacked(
          "[!!!] IInvariant violation: senior token total asset (",
          Strings.toString(totalAssetSenior),
          ") differs from deposited amount (",
          Strings.toString(seniorAmount),
          ")"
        )
      )
    );

    uint maxClaimableJunior = juniorDepositToken.maximumClaimable(owner);
    uint maxClaimableSenior = seniorDepositToken.maximumClaimable(owner);

    require(
      maxClaimableJunior == 0,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: claimable junior token amount (",
          Strings.toString(maxClaimableJunior),
          ") differs from 0 after depositing ",
          Strings.toString(juniorAmount)
        )
      )
    );
    require(
      maxClaimableSenior == 0,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: claimable senior token amount (",
          Strings.toString(maxClaimableSenior),
          ") differs from 0 after depositing ",
          Strings.toString(seniorAmount)
        )
      )
    );

    uint maxRedeemJunior = juniorDepositToken.maxRedeem(owner);
    uint maxRedeemSenior = seniorDepositToken.maxRedeem(owner);

    require(
      maxRedeemJunior == juniorAmount,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: max redeem junior token amount (",
          Strings.toString(maxRedeemJunior),
          ") differs from deposited amount ",
          Strings.toString(juniorAmount)
        )
      )
    );
    require(
      maxRedeemSenior == seniorAmount,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: max redeem senior token amount (",
          Strings.toString(maxRedeemSenior),
          ") differs from deposited amount ",
          Strings.toString(seniorAmount)
        )
      )
    );

    uint unbondingJunior = juniorDepositToken.unbonding(owner);
    uint unbondingSenior = seniorDepositToken.unbonding(owner);

    require(
      unbondingJunior == 0,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: unbounding junior token amount (",
          Strings.toString(unbondingJunior),
          ") differs from 0 after depositing ",
          Strings.toString(juniorAmount)
        )
      )
    );
    require(
      unbondingSenior == 0,
      string(
        abi.encodePacked(
          "[!!!] Invariant violation: unbounding senior token amount (",
          Strings.toString(unbondingSenior),
          ") differs from 0 after depositing ",
          Strings.toString(seniorAmount)
        )
      )
    );
  }
}

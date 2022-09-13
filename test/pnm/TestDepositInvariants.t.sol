// pragma solidity 0.8.9;
pragma solidity 0.8.17;

import {TestWrapper} from "test/pnm/TestWrapper.t.sol";

contract TestDepositInvariants is TestWrapper {
  const JUNIOR_AMOUNT = 1 * 10 ** 18;
  const SENIOR_AMOUNT = 2 * 10 ** 18;

    function setUp() public {
      deploy();

      this.voyage.deposit(this.crab.address, 0, JUNIOR_AMOUNT);
      this.voyage.deposit(this.crab.address, 1, SENIOR_AMOUNT);
    }

    function check() public override {
      const juniorTokenBalance = this.juniorDepositToken.balanceOf(A);
      const seniorTokenBalance = this.seniorDepositToken.balanceOf(A);

      require(
        juniorTokenBalance == JUNIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: junior token balance (",
            Strings.toString(juniorTokenBalance),
            ") differs from deposited amount (",
            Strings.toString(JUNIOR_AMOUNT),
            ")"
          )
        )
      );
      require(
        seniorTokenBalance == SENIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: senior token balance (",
            Strings.toString(seniorTokenBalance),
            ") differs from deposited amount (",
            Strings.toString(SENIOR_AMOUNT),
            ")"
          )
        )
      );

      
      const maxWithdrawJuniorTokenAmount = this.juniorDepositToken.maxWithdraw(A);
      const maxWithdrawSeniorTokenAmount = this.seniorDepositToken.maxWithdraw(A);

      require(
        maxWithdrawJuniorTokenAmount == JUNIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: junior token max withdraw (",
            Strings.toString(maxWithdrawJuniorTokenAmount),
            ") differs from deposited amount (",
            Strings.toString(JUNIOR_AMOUNT),
            ")"
          )
        )
      );
      require(
        maxWithdrawSeniorTokenAmount == SENIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: senior token max withdraw (",
            Strings.toString(maxWithdrawSeniorTokenAmount),
            ") differs from deposited amount (",
            Strings.toString(SENIOR_AMOUNT),
            ")"
          )
        )
      );

      const totalAssetJunior = this.juniorDepositToken.totalAssets();
      const totalAssetSenior = this.seniorDepositToken.totalAssets();

      require(
        totalAssetJunior == JUNIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: junior token total asset (",
            Strings.toString(totalAssetJunior),
            ") differs from deposited amount (",
            Strings.toString(JUNIOR_AMOUNT),
            ")"
          )
        )
      );
      require(
        totalAssetSenior == SENIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] IInvariant violation: senior token total asset (",
            Strings.toString(totalAssetSenior),
            ") differs from deposited amount (",
            Strings.toString(SENIOR_AMOUNT),
            ")"
          )
        )
      );

      const maxClaimableJunior = this.juniorDepositToken.maximumClaimable(A);
      const maxClaimableSenior = this.seniorDepositToken.maximumClaimable(A);

      require(
        maxClaimableJunior == 0,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: claimable junior token amount (",
            Strings.toString(maxClaimableJunior),
            ") differs from 0 after depositing ",
            Strings.toString(JUNIOR_AMOUNT)
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
            Strings.toString(SENIOR_AMOUNT)
          )
        )
      );

      const maxRedeemJunior = this.juniorDepositToken.maxRedeem(A);
      const maxRedeemSenior = this.seniorDepositToken.maxRedeem(A);

      require(
        maxRedeemJunior == JUNIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: max redeem junior token amount (",
            Strings.toString(maxRedeemJunior),
            ") differs from deposited amount ",
            Strings.toString(JUNIOR_AMOUNT)
          )
        )
      );
      require(
        maxRedeemSenior == SENIOR_AMOUNT,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: max redeem senior token amount (",
            Strings.toString(maxRedeemSenior),
            ") differs from deposited amount ",
            Strings.toString(SENIOR_AMOUNT)
          )
        )
      );

      const unbondingJunior = this.juniorDepositToken.unbonding(A);
      const unbondingSenior = this.seniorDepositToken.unbonding(A);

      require(
        unbondingJunior == 0,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: unbounding junior token amount (",
            Strings.toString(unbondingJunior),
            ") differs from 0 after depositing ",
            Strings.toString(JUNIOR_AMOUNT)
          )
        )
      );
      require(
        unbondingSenior == 0,
        string(
          abi.encodePacked(
            "[!!!] Invariant violation: claimable senior token amount (",
            Strings.toString(unbondingSenior),
            ") differs from 0 after depositing ",
            Strings.toString(SENIOR_AMOUNT)
          )
        )
      );
  }
}

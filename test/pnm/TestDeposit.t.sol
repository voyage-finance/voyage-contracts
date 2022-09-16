pragma solidity ^0.8.9;

import "./TestBase.t.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/voyage/libraries/LibLoan.sol";
import {Tranche} from "contracts/voyage/libraries/LibAppStorage.sol";

contract TestDepositInvariants is TestBase {
    uint256 juniorAmount = 1 * 10**18;
    uint256 seniorAmount = 2 * 10**18;

    function setUp() public {
        deploy();

        LiquidityFacet(address(voyage)).deposit(
            address(crab),
            Tranche.JUNIOR,
            juniorAmount
        );
        LiquidityFacet(address(voyage)).deposit(
            address(crab),
            Tranche.SENIOR,
            seniorAmount
        );
    }

    function check() public override {
        uint256 juniorTokenBalance = juniorDepositToken.balanceOf(owner);
        uint256 seniorTokenBalance = seniorDepositToken.balanceOf(owner);

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

        uint256 maxWithdrawJuniorTokenAmount = juniorDepositToken.maxWithdraw(
            owner
        );
        uint256 maxWithdrawSeniorTokenAmount = seniorDepositToken.maxWithdraw(
            owner
        );

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

        uint256 totalAssetJunior = juniorDepositToken.totalAssets();
        uint256 totalAssetSenior = seniorDepositToken.totalAssets();

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

        // JuniorDepositToken does not have a maximumClaimable function
        uint256 maxClaimableSenior = seniorDepositToken.maximumClaimable(owner);

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

        uint256 maxRedeemJunior = juniorDepositToken.maxRedeem(owner);
        uint256 maxRedeemSenior = seniorDepositToken.maxRedeem(owner);

        require(
            maxRedeemJunior == juniorAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: max redeem junior token amount (",
                    Strings.toString(maxRedeemJunior),
                    ") differs from deposited amount (",
                    Strings.toString(juniorAmount),
                    ")"
                )
            )
        );
        require(
            maxRedeemSenior == seniorAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: max redeem senior token amount (",
                    Strings.toString(maxRedeemSenior),
                    ") differs from deposited amount (",
                    Strings.toString(seniorAmount),
                    ")"
                )
            )
        );

        // JuniorDepositToken does not have a unbonding function
        uint256 unbondingSenior = seniorDepositToken.unbonding(owner);

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

        LibLoan.LoanDetail memory loan = DataProviderFacet(address(voyage))
            .getLoanDetail(address(vault), address(crab), 0);

        require(
            loan.epoch <= loan.term,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: loan epoch (",
                    Strings.toString(loan.epoch),
                    ") is greater than loan term (",
                    Strings.toString(loan.term),
                    ")"
                )
            )
        );

        LiquidityFacet(address(voyage)).withdraw(
            address(crab),
            Tranche.JUNIOR,
            juniorAmount
        );

        require(
            address(crab).balance == juniorAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: junior token withdrawn amount (",
                    Strings.toString(address(crab).balance),
                    ") differs from deposited amount (",
                    Strings.toString(juniorAmount),
                    ")"
                )
            )
        );

        LiquidityFacet(address(voyage)).withdraw(
            address(crab),
            Tranche.SENIOR,
            seniorAmount
        );

        require(
            address(crab).balance == juniorAmount + seniorAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: senior token withdrawn amount (",
                    Strings.toString(address(crab).balance - juniorAmount),
                    ") differs from deposited amount (",
                    Strings.toString(seniorAmount),
                    ")"
                )
            )
        );
    }
}

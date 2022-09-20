pragma solidity 0.8.9;

import "./TestBase.t.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LibLoan} from "contracts/voyage/libraries/LibLoan.sol";
import {Tranche} from "contracts/voyage/libraries/LibAppStorage.sol";

contract TestDeposit is TestBase {
    uint256 juniorDepositAmount = 1 * 10**18;
    uint256 seniorDepositAmount = 2 * 10**18;

    function setUp() public {
        deploy();

        LiquidityFacet(address(voyage)).deposit(
            address(crab),
            Tranche.JUNIOR,
            juniorDepositAmount
        );
        LiquidityFacet(address(voyage)).deposit(
            address(crab),
            Tranche.SENIOR,
            seniorDepositAmount
        );
    }

    function check() public override {
        uint256 juniorTokenBalance = juniorDepositToken.balanceOf(owner);
        uint256 seniorTokenBalance = seniorDepositToken.balanceOf(owner);

        require(
            juniorTokenBalance == juniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: junior token balance (",
                    Strings.toString(juniorTokenBalance),
                    ") differs from deposited amount (",
                    Strings.toString(juniorDepositAmount),
                    ")"
                )
            )
        );
        require(
            seniorTokenBalance == seniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: senior token balance (",
                    Strings.toString(seniorTokenBalance),
                    ") differs from deposited amount (",
                    Strings.toString(seniorDepositAmount),
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
            maxWithdrawJuniorTokenAmount == juniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: junior token max withdraw (",
                    Strings.toString(maxWithdrawJuniorTokenAmount),
                    ") differs from deposited amount (",
                    Strings.toString(juniorDepositAmount),
                    ")"
                )
            )
        );
        require(
            maxWithdrawSeniorTokenAmount == seniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: senior token max withdraw (",
                    Strings.toString(maxWithdrawSeniorTokenAmount),
                    ") differs from deposited amount (",
                    Strings.toString(seniorDepositAmount),
                    ")"
                )
            )
        );

        uint256 totalAssetJunior = juniorDepositToken.totalAssets();
        uint256 totalAssetSenior = seniorDepositToken.totalAssets();

        require(
            totalAssetJunior == juniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: junior token total asset (",
                    Strings.toString(totalAssetJunior),
                    ") differs from deposited amount (",
                    Strings.toString(juniorDepositAmount),
                    ")"
                )
            )
        );
        require(
            totalAssetSenior == seniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] IInvariant violation: senior token total asset (",
                    Strings.toString(totalAssetSenior),
                    ") differs from deposited amount (",
                    Strings.toString(seniorDepositAmount),
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
                    Strings.toString(seniorDepositAmount)
                )
            )
        );

        uint256 maxRedeemJunior = juniorDepositToken.maxRedeem(owner);
        uint256 maxRedeemSenior = seniorDepositToken.maxRedeem(owner);

        require(
            maxRedeemJunior == juniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: max redeem junior token amount (",
                    Strings.toString(maxRedeemJunior),
                    ") differs from deposited amount (",
                    Strings.toString(juniorDepositAmount),
                    ")"
                )
            )
        );
        require(
            maxRedeemSenior == seniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: max redeem senior token amount (",
                    Strings.toString(maxRedeemSenior),
                    ") differs from deposited amount (",
                    Strings.toString(seniorDepositAmount),
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
                    Strings.toString(seniorDepositAmount)
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
            juniorDepositAmount
        );

        require(
            address(crab).balance == juniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: junior token withdrawn amount (",
                    Strings.toString(address(crab).balance),
                    ") differs from deposited amount (",
                    Strings.toString(juniorDepositAmount),
                    ")"
                )
            )
        );

        LiquidityFacet(address(voyage)).withdraw(
            address(crab),
            Tranche.SENIOR,
            seniorDepositAmount
        );

        require(
            address(crab).balance == juniorDepositAmount + seniorDepositAmount,
            string(
                abi.encodePacked(
                    "[!!!] Invariant violation: senior token withdrawn amount (",
                    Strings.toString(
                        address(crab).balance - juniorDepositAmount
                    ),
                    ") differs from deposited amount (",
                    Strings.toString(seniorDepositAmount),
                    ")"
                )
            )
        );
    }
}

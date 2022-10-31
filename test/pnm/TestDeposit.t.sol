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
        setupTest();

        vm.startPrank(owner);
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
        _approveVoyage();
        vm.stopPrank();
    }

    function invariantBalance() public {
        // hacker's operation should not affect the balance
        uint256 juniorTokenBalance = juniorDepositToken.balanceOf(owner);
        uint256 seniorTokenBalance = seniorDepositToken.balanceOf(owner);
        assert(juniorTokenBalance == juniorDepositAmount);
        assert(seniorTokenBalance == seniorDepositAmount);

        uint256 maxWithdrawJuniorTokenAmount = juniorDepositToken.maxWithdraw(
            owner
        );
        uint256 maxWithdrawSeniorTokenAmount = seniorDepositToken.maxWithdraw(
            owner
        );
        assert(maxWithdrawJuniorTokenAmount == juniorDepositAmount);
        assert(maxWithdrawSeniorTokenAmount == seniorDepositAmount);

        uint256 totalAssetJunior = juniorDepositToken.totalAssets();
        uint256 totalAssetSenior = seniorDepositToken.totalAssets();
        assert(totalAssetJunior == juniorDepositAmount);
        assert(totalAssetSenior == seniorDepositAmount);

        // JuniorDepositToken does not have a maximumClaimable function
        uint256 maxClaimableSenior = seniorDepositToken.maximumClaimable(owner);
        assert(maxClaimableSenior == 0);

        uint256 maxRedeemJunior = juniorDepositToken.maxRedeem(owner);
        uint256 maxRedeemSenior = seniorDepositToken.maxRedeem(owner);
        assert(maxRedeemJunior == juniorDepositAmount);
        assert(maxRedeemSenior == seniorDepositAmount);
    }

    function invariantUnbonding() public {
        uint256 unbondingSenior = seniorDepositToken.unbonding(owner);
        assert(unbondingSenior == 0);
    }

    function invariantTerm() public {
        LibLoan.LoanDetail memory loan = DataProviderFacet(address(voyage))
            .getLoanDetail(address(vault), address(crab), 0);
        assert(loan.epoch <= loan.term);
    }

    function invariantWithdraw() public {
        vm.startPrank(owner);

        uint256 wethBalanceInit = weth.balanceOf(owner);
        LiquidityFacet(address(voyage)).withdraw(
            address(crab),
            Tranche.JUNIOR,
            juniorDepositAmount
        );

        uint256 wethBalanceAfterWithdrawingJunior = weth.balanceOf(owner);
        assert(
            wethBalanceAfterWithdrawingJunior ==
                wethBalanceInit + juniorDepositAmount
        );
        uint256 juniorBalanceAfter = LiquidityFacet(address(voyage)).balance(
            address(crab),
            owner,
            Tranche.JUNIOR
        );
        assert(juniorBalanceAfter == 0);

        LiquidityFacet(address(voyage)).withdraw(
            address(crab),
            Tranche.SENIOR,
            seniorDepositAmount
        );
        uint256 seniorBalanceAfter = LiquidityFacet(address(voyage)).balance(
            address(crab),
            owner,
            Tranche.SENIOR
        );
        assert(seniorBalanceAfter == 0);
        uint256 wethBalanceAfterWithdrawSenior = weth.balanceOf(owner);
        assert(
            wethBalanceAfterWithdrawSenior == wethBalanceAfterWithdrawingJunior
        );

        vm.stopPrank();
    }

    function invariantClaim() public {
        vm.startPrank(owner);

        uint256 wethBalanceInit = weth.balanceOf(owner);

        LiquidityFacet(address(voyage)).withdraw(
            address(crab),
            Tranche.SENIOR,
            seniorDepositAmount
        );

        uint256 wethBalanceAfterWithdraw = weth.balanceOf(owner);
        assert(wethBalanceInit == wethBalanceAfterWithdraw);

        seniorDepositToken.claim();
        uint256 wethBalanceAfterClaim = weth.balanceOf(owner);
        assert(
            wethBalanceAfterClaim ==
                wethBalanceAfterWithdraw + seniorDepositAmount
        );
        vm.stopPrank();
    }
}

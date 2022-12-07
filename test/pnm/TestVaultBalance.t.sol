pragma solidity 0.8.9;

import "./TestBase.t.sol";
import "contracts/voyage/adapter/LooksRareAdapter.sol";

contract TestVaultBalance is TestBase {
    address ownerVault;
    ILooksRareExchange looksRare = ILooksRareExchange(0x1AA777972073Ff66DCFDeD85749bDD555C0665dA);
    MakerOrder makeOrder;
    TakerOrder takeOrder;

    function setUp() public {
        deploy();
        setupTest();

        vm.startPrank(owner);
        priceOracle.updateTwap(address(crab), 10 wei);
        uint juniorDepositAmount = 50 wei;
        ownerVault = DataProviderFacet(address(voyage)).getVault(owner);
        LiquidityFacet(address(voyage)).deposit(
            address(crab),
            Tranche.JUNIOR,
            juniorDepositAmount
        );
        vm.stopPrank();
        makeOrder = MakerOrder(
            true,
            0xAc786F3E609eeBC3830A26881bd026B6b9211ae2,
            0xd10E39Afe133eF729aE7f4266B26d173BC5AD1B1,
            10 wei,
            1,
            1,
            0x732319A3590E4fA838C111826f9584a9A2fDEa1a,
            0xc778417E063141139Fce010982780140Aa0cD5Ab,
            0,
            1661852317,
            1662457076,
            9800,
            "",
            27,
            0x66f2bf329cf885420596359ed1b435ef3ffe3b35efcbf10854b393724482369b,
            0x6db5028edf4f90eba89576e8181a4b4051ae9053b08b0dfb5c0fd6c580b73f66
        );
        takeOrder = TakerOrder(
            false,
            ownerVault,
            makeOrder.price,
            makeOrder.tokenId,
            9800,
            ""
        );
    }

    function invariantVaultBalance() public {
        vm.prank(agent);
        (bool success,) = address(voyage).call(
            abi.encodeWithSignature("buyNow(address,uint256,address,address,bytes)", 
            address(crab),
            1,
            address(ownerVault),
            address(mockMarketPlace),
            abi.encodeWithSignature(
                "ILooksRareExchange.matchAskWithTakerBidUsingETHAndWETH(TakerOrder,MakerOrder)", 
                takeOrder, 
                makeOrder
            )
        ));
        assert(success == false);
    }
}

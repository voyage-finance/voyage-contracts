pragma solidity ^0.8.9;

import "@pwnednomore/contracts/Agent.sol";
import "../../contracts/voyage/Voyage.sol";
import "../../contracts/voyage/infra/PriceOracle.sol";
import "../../contracts/voyage/strategy/DefaultReserveInterestRateStrategy.sol";
import "../../contracts/voyage/tokenization/SeniorDepositToken.sol";
import "../../contracts/voyage/tokenization/JuniorDepositToken.sol";
import "../../contracts/voyage/adapter/LooksRareAdapter.sol";
import "../../contracts/voyage/adapter/SeaportAdapter.sol";
import "../../contracts/mock/WETH9.sol";
import "../../contracts/mock/Crab.sol";
import "../../contracts/mock/MockMarketplace.sol";
import "../../contracts/mock/MockSeaport.sol";
import "../../contracts/shared/gsn/VoyagePaymaster.sol";

contract TestWrapper is Agent {
    address owner = address(0x0);
    address alice = address(0x1);
    address bob = address(0x2);
    address treasury = address(0x9);
    address forwarder = address(0xa);

    address internal vault;
    
    const WAD = 10 ** 18;
    const RAY = 10 ** 27;
    
    Voyage internal voyage;
    Crab internal crab;
    PriceOracle internal priceOracle;
    WETH9 internal weth;
    VoyagePaymaster internal paymaster;
    MockMarketPlace internal marketPlace;
    LooksRareAdapter internal looksRareAdapter;
    SeaportAdapter internal seaportAdapter;
    MockSeaport internal seaport;
    DefaultReserveInterestRateStrategy internal defaultReserveInterestRateStrategy;
    SeniorDepositToken internal seniorDepositToken;
    JuniorDepositToken internal juniorDepositToken;

    function deploy() internal {
        // voyage
        voyage = new Voyage(owner);

        // infra
        weth = new WETH9();
        deal(weth, 100000 wei);

        paymaster = new VoyagePaymaster(voyage, weth, treasury);
        paymaster.setTrustedForwarder(forwarder);

        priceOracle = new PriceOracle();

        // adapter
        looksRareAdapter = new LooksRareAdapter();
        seaportAdapter = new SeaportAdapter(weth);

        // tokenization
        crab = new Crab("Crab", "CRAB");
        marketPlace = new MockMarketPlace();
        seaport = new MockSeaport();

        uint256 utilisationRate = 0.8 * RAY;
        uint256 slope = 0.04 * RAY;
        uint256 baseInterest = 0.18 * RAY;

        defaultReserveInterestRateStrategy = new DefaultReserveInterestRateStrategy(
            utilisationRate,
            slope,
            baseInterest
        );
        
        // reserve initialization
        voyage.initReserve(crab, weth, defaultReserveInterestRateStrategy, priceOracle);

        // --- 105%
        voyage.setLiquidationBonus(crab, 10500);
        voyage.setIncomeRatio(crab, 0.5 * 1e4);
        voyage.setLoanParams(crab, 30, 90, 10);
        voyage.activateReserve(crab);
        uint40 cutPercentage = 200; //2%
        voyage.updateProtocolFee(owner, cutPercentage);
        voyage.updateMarketPlaceData(marketPlace, looksRareAdapter);
        voyage.updateMarketPlaceData(seaport, seaportAdapter);

        address (senior, junior) = voyage.getDepositTokens(crab);

        seniorDepositToken = new SeniorDepositToken(senior);
        juniorDepositToken = new JuniorDepositToken(junior);
        weth.approve(voyage, type(uint256).max);

        // vault initialization
        // --- create an empty vault
        bytes20 salt = bytes20(keccak256(abi.encodePacked("PwnedNoMore")));
        voyage.createVault(owner, salt);
        vault = voyage.getVault(owner);
        // --- fund vault for the first payment
        deal(owner, 10000 wei);
        prank(owner);
        vault.send(100 wei);
        weth.transfer(vault, 10 wei);
        weth.approve(vault, type(uint256).max);

        // the "todo delete" section, won't transcribe it till we need it.
    }
}

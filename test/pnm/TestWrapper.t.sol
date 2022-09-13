pragma solidity ^0.8.9;

import "@pwnednomore/contracts/Agent.sol";
import "../../contracts/voyage/Voyage.sol";
import "../../contracts/voyage/infra/PriceOracle.sol";
import "../../contracts/voyage/strategy/DefaultReserveInterestRateStrategy.sol";
import "../../contracts/voyage/tokenization/SeniorDepositToken.sol";
import "../../contracts/voyage/tokenization/JuniorDepositToken.sol";
import "../../contracts/mock/WETH9.sol";
import "../../contracts/mock/Crab.sol";
import "../../contracts/mock/MockMarketplace.sol";
import "../../contracts/mock/MockSeaport.sol";
import "../../contracts/shared/gsn/VoyagePaymaster.sol";

contract TestWrapper is Agent {
    address owner = address(0x1);
    Voyage internal voyage;
    Crab internal crab;
    PriceOracle internal priceOracle;
    WETH9 internal weth;
    VoyagePaymaster internal paymaster;
    MockMarketPlace internal marketPlace;
    MockSeaport internal seaport;
    DefaultReserveInterestRateStrategy internal defaultReserveInterestRateStrategy;
    SeniorDepositToken internal seniorDepositToken;
    JuniorDepositToken internal juniorDepositToken;

    function deploy() internal {
        // voyage
        voyage = new Voyage(owner);

        // infra
        paymaster = new VoyagePaymaster();
        paymaster.setTrustedForwarder(address(this));
        priceOracle = new PriceOracle();
        weth = new WETH9();
        weth.deposit({value: 100000 wei});

        // adapter

        // tokenization
        crab = new Crab("Crab", "CRAB");
        marketPlace = new MockMarketPlace();
        seaport = new MockSeaport();
        defaultReserveInterestRateStrategy = new DefaultReserveInterestRateStrategy();
        
        // reserve initialization
        voyage.initReserve(crab, weth, defaultReserveInterestRateStrategy, priceOracle);

        // 105%
        voyage.setLiquidationBonus(crab, 10500);
        voyage.setIncomeRatio(crab, 0.5 * 1e4);
        voyage.setLoanParams(crab, 30, 90, 10);
        voyage.activateReserve(crab);
        uint40 cutPercentage = 200; //2%
        voyage.updateProtocolFee(owner, cutPercentage);
        voyage.updateMarketPlaceData(marketPlace, looksRareAdapter);
        voyage.updateMarketPlaceData(seaport, seaportAdapter);

        address (senior, junior) = voyage.getDepositTokens(crab.address);

        seniorDepositToken = new SeniorDepositToken(senior);
        juniorDepositToken = new JuniorDepositToken(junior);
        weth.approve(voyage, type(uint256).max);
    }
}
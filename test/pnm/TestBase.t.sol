pragma solidity ^0.8.9;

import "@pwnednomore/contracts/Agent.sol";
import "contracts/voyage/Voyage.sol";
import "contracts/voyage/tokenization/SeniorDepositToken.sol";
import "contracts/voyage/tokenization/JuniorDepositToken.sol";

import "contracts/mock/WETH9.sol";

import "contracts/shared/gsn/VoyagePaymaster.sol";
import "contracts/voyage/infra/PriceOracle.sol";
import "contracts/voyage/adapter/LooksRareAdapter.sol";
import "contracts/voyage/adapter/SeaportAdapter.sol";

import "contracts/mock/Crab.sol";
import {MockMarketPlace} from "contracts/mock/MockMarketplace.sol";
import {MockSeaport} from "contracts/mock/MockSeaport.sol";

import "contracts/voyage/strategy/DefaultReserveInterestRateStrategy.sol";
import "contracts/vault/Vault.sol";
import "contracts/shared/diamond/facets/DiamondCutFacet.sol";
import "contracts/shared/diamond/facets/DiamondLoupeFacet.sol";
import "contracts/shared/diamond/facets/OwnershipFacet.sol";

import {InitDiamond} from "contracts/voyage/InitDiamond.sol";

import "contracts/voyage/facets/LiquidityFacet.sol";
import "contracts/voyage/facets/ConfigurationFacet.sol";
import "contracts/voyage/facets/DataProviderFacet.sol";
import {PaymentsFacet} from "contracts/shared/facets/PaymentsFacet.sol";
import "contracts/voyage/facets/MarketplaceAdapterFacet.sol";

contract TestBase is Agent {
    address owner = address(0x0);
    address alice = address(0x1);
    address bob = address(0x2);
    address treasury = address(0x9);
    address forwarder = address(0xa);

    address internal vault;
    
    uint256 WAD = 10 ** 18;
    uint256 RAY = 10 ** 27;
    
    Voyage internal voyage;
    SeniorDepositToken internal seniorDepositToken;
    JuniorDepositToken internal juniorDepositToken;
    WETH9 internal weth;
    VoyagePaymaster internal paymaster;
    PriceOracle internal priceOracle;
    LooksRareAdapter internal looksRareAdapter;
    SeaportAdapter internal seaportAdapter;

    Crab internal crab;
    MockMarketPlace internal mockMarketPlace;
    MockSeaport internal mockSeaport;
    DefaultReserveInterestRateStrategy internal defaultReserveInterestRateStrategy;

    function deploy() internal {
        _deploy_voyager();
        _deploy_external();
        _setup_test();
    }

    function _deploy_voyager() internal {
        voyage = new Voyage(owner);

        vm.startBroadcast();
        seniorDepositToken = new SeniorDepositToken();
        juniorDepositToken = new JuniorDepositToken();
        Vault vault = new Vault();
        priceOracle = new PriceOracle();
        looksRareAdapter = new LooksRareAdapter();
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        weth = new WETH9();
        seaportAdapter = new SeaportAdapter(address(weth));
        paymaster = new VoyagePaymaster(
            address(voyage), address(weth), treasury
        );

        InitDiamond initDiamond = new InitDiamond();

        SecurityFacet securityFacet = new SecurityFacet();
        LiquidityFacet liquidityFacet = new LiquidityFacet();
        LoanFacet loanFacet = new LoanFacet();
        VaultFacet vaultFacet = new VaultFacet();
        ConfigurationFacet configurationFacet = new ConfigurationFacet();
        DataProviderFacet dataProviderFacet = new DataProviderFacet();
        PaymentsFacet paymentsFacet = new PaymentsFacet();
        MarketplaceAdapterFacet marketplaceAdapterFacet = new MarketplaceAdapterFacet();
        vm.stopPrank();

        voyage.diamondCut([ // TODO: need to use `FacetCut` struct
            securityFacet,
            liquidityFacet,
            loanFacet,
            vaultFacet,
            configurationFacet,
            dataProviderFacet,
            paymentsFacet,
            marketplaceAdapterFacet
        ], 
        address(initDiamond), 
        initDiamond.init(
            InitDiamond.Args(
                address(owner),
                address(seniorDepositToken),
                address(juniorDepositToken),
                address(vault),
                address(diamondCutFacet),
                address(diamondLoupeFacet),
                address(ownershipFacet),
                address(weth),
                address(forwarder),
                address(paymaster)
            )
        ));
    }

    function _deploy_external() internal {
        vm.startPrank();
        crab = new Crab("Mock Crab", "MC");
        mockMarketPlace = new MockMarketPlace();
        mockSeaport = new MockSeaport();

        uint256 utilisationRate = 8 * RAY / 10;
        uint256 slope = 4 * RAY / 100;
        uint256 baseInterest = 18 * RAY / 100;

        defaultReserveInterestRateStrategy = new DefaultReserveInterestRateStrategy(
            utilisationRate,
            slope,
            baseInterest
        );
        vm.stopPrank();
    }

    function _setup_test() internal {
        // infra
        vm.deal(address(weth), 100000 wei);
        paymaster.setTrustedForwarder(forwarder);

        // adapter

        // tokenization

        
        // reserve initialization
        voyage.initReserve(
            crab, 
            weth, 
            defaultReserveInterestRateStrategy, 
            priceOracle
        );

        // --- 105%
        voyage.setLiquidationBonus(crab, 10500);
        voyage.setIncomeRatio(crab, 0.5 * 1e4);
        voyage.setLoanParams(crab, 30, 90, 10);
        voyage.activateReserve(crab);
        uint40 cutPercentage = 200; //2%
        voyage.updateProtocolFee(owner, cutPercentage);
        // voyage.updateMarketPlaceData(marketPlace, looksRareAdapter);
        // voyage.updateMarketPlaceData(seaport, seaportAdapter);

        (address senior, uint256 junior) = voyage.getDepositTokens(crab);

        weth.approve(voyage, type(uint256).max);

        // vault initialization
        // --- create an empty vault
        bytes20 salt = bytes20(keccak256(abi.encodePacked("PwnedNoMore")));
        voyage.createVault(owner, salt);
        vault = voyage.getVault(owner);
        // --- fund vault for the first payment
        vm.deal(owner, 10000 wei);
        vm.prank(owner);
        vault.send(100 wei);
        weth.transfer(vault, 10 wei);
        weth.approve(vault, type(uint256).max);

        // the "todo delete" section, won't transcribe it till we need it.
    }
}

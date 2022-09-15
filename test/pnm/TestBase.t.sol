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
import {MockForwarder} from "contracts/mock/MockForwarder.sol";

import "contracts/voyage/strategy/DefaultReserveInterestRateStrategy.sol";
import "contracts/vault/Vault.sol";
import "contracts/shared/diamond/facets/DiamondCutFacet.sol";
import "contracts/shared/diamond/facets/DiamondLoupeFacet.sol";
import "contracts/shared/diamond/facets/OwnershipFacet.sol";

import {InitDiamond} from "contracts/voyage/InitDiamond.sol";
import "contracts/shared/diamond/interfaces/IDiamondCut.sol";

import "contracts/voyage/facets/LiquidityFacet.sol";
import "contracts/voyage/facets/ConfigurationFacet.sol";
import "contracts/voyage/facets/DataProviderFacet.sol";
import {PaymentsFacet} from "contracts/shared/facets/PaymentsFacet.sol";
import "contracts/voyage/facets/MarketplaceAdapterFacet.sol";

contract TestBase is Agent, IDiamondCut {
    address owner = address(0x0);
    address alice = address(0x1);
    address bob = address(0x2);
    address treasury = address(0x9);
    address forwarder = address(0xa);

    uint256 WAD = 10**18;
    uint256 RAY = 10**27;

    Voyage internal voyage;
    SeniorDepositToken internal seniorDepositToken;
    JuniorDepositToken internal juniorDepositToken;
    Vault internal vault;
    WETH9 internal weth;
    VoyagePaymaster internal paymaster;
    PriceOracle internal priceOracle;
    LooksRareAdapter internal looksRareAdapter;
    SeaportAdapter internal seaportAdapter;

    Crab internal crab;
    MockMarketPlace internal mockMarketPlace;
    MockSeaport internal mockSeaport;
    MockForwarder internal mockForwarder;
    DefaultReserveInterestRateStrategy
        internal defaultReserveInterestRateStrategy;

    function deploy() internal {
        _deploy000Mock();
        _deploy001Vtoken();
        _deploy002Vault();
        _deploy003MarketplaceAdapter();
        _deploy004InterestRateStrategy();
        _deploy005PriceOracle();
        _deploy006Diamond();
        _deploy007Facets();
        _deploy008Paymaster();
    }

    function _deploy000Mock() internal {
        vm.startPrank(owner);
        weth = new WETH9();
        mockForwarder = new MockForwarder();
        
        crab = new Crab("Mocked Crab", "MC");
        mockMarketPlace = new MockMarketPlace();
        mockSeaport = new MockSeaport();
        vm.stopPrank();
    }

    function _deploy001Vtoken() internal {
        vm.startPrank(owner);
        seniorDepositToken = new SeniorDepositToken();
        juniorDepositToken = new JuniorDepositToken();
        vm.stopPrank();
    }

    function _deploy002Vault() internal {
        vm.startPrank(owner);
        vault = new Vault();
        vm.stopPrank();
    }

    function _deploy003MarketplaceAdapter() internal {
        vm.startPrank(owner);
        looksRareAdapter = new LooksRareAdapter();
        seaportAdapter = new SeaportAdapter(address(weth));
        vm.stopPrank();
    }

    function _deploy004InterestRateStrategy() internal {
        vm.startPrank(owner);
        uint256 utilisationRate = (8 * RAY) / 10;
        uint256 slope = (4 * RAY) / 100;
        uint256 baseInterest = (18 * RAY) / 100;

        defaultReserveInterestRateStrategy = new DefaultReserveInterestRateStrategy(
            utilisationRate,
            slope,
            baseInterest
        );
        vm.stopPrank();
    }

    function _deploy005PriceOracle() internal {
        vm.startPrank(owner);
        priceOracle = new PriceOracle();
        vm.stopPrank();
    }

    function _deploy006Diamond() internal {
        vm.startPrank(owner);
        voyage = new Voyage(owner);
        vm.stopPrank();
    }

    function _deploy007Facets() internal {
        vm.startPrank(owner);

        InitDiamond initDiamond = new InitDiamond();

        SecurityFacet securityFacet = new SecurityFacet();
        LiquidityFacet liquidityFacet = new LiquidityFacet();
        LoanFacet loanFacet = new LoanFacet();
        VaultFacet vaultFacet = new VaultFacet();
        ConfigurationFacet configurationFacet = new ConfigurationFacet();
        DataProviderFacet dataProviderFacet = new DataProviderFacet();
        PaymentsFacet paymentsFacet = new PaymentsFacet();
        MarketplaceAdapterFacet marketplaceAdapterFacet = new MarketplaceAdapterFacet();

        FacetCut[] memory diamondCut = [
            FacetCut({
                facetAddress: address(securityFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("SecurityFacet")
            }),
            FacetCut({
                facetAddress: address(liquidityFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("LiquidityFacet")
            }),
            FacetCut({
                facetAddress: address(loanFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("LoanFacet")
            }),
            FacetCut({
                facetAddress: address(vaultFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("VaultFacet")
            }),
            FacetCut({
                facetAddress: address(configurationFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("ConfigurationFacet")
            }),
            FacetCut({
                facetAddress: address(dataProviderFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("DataProviderFacet")
            }),
            FacetCut({
                facetAddress: address(paymentsFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("PaymentsFacet")
            }),
            FacetCut({
                facetAddress: address(marketplaceAdapterFacet), 
                action: FacetCutAction.Add, 
                functionSelectors: _generateSelectors("MarketplaceAdapterFacet")
           } )
        ];

        IDiamondCut(address(voyage)).diamondCut(
            diamondCut,
            address(initDiamond),
            initDiamond.init(
                InitDiamond.Args({
                    initOwner: address(owner),
                    seniorDepositTokenImpl: address(seniorDepositToken),
                    juniorDepositTokenImpl: address(juniorDepositToken),
                    vaultImpl: address(vault),
                    weth9: address(weth)
                })
            )
        );
        vm.stopPrank();
    }

    function _deploy008Paymaster() internal {
        vm.startPrank(owner);
        paymaster = new VoyagePaymaster(
            address(voyage),
            address(weth),
            treasury
        );
        paymaster.setTrustedForwarder(forwarder);
        paymaster.setRelayHub(forwarder);
        vm.stopPrank();
    }

    function _generateSelectors(string memory _facetName)
        internal
        returns (bytes4[] memory selectors)
    {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
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

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}

}

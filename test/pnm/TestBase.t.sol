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

import {LiquidityFacet} from "contracts/voyage/facets/LiquidityFacet.sol";
import "contracts/voyage/facets/ConfigurationFacet.sol";
import "contracts/voyage/facets/DataProviderFacet.sol";

contract TestBase is Agent {
    address owner = address(0x42);
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

        IDiamondCut.FacetCut[] memory diamondCut = new IDiamondCut.FacetCut[](
            6
        );
        diamondCut[0] = (
            IDiamondCut.FacetCut({
                facetAddress: address(securityFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: _generateSelectors("SecurityFacet")
            })
        );
        diamondCut[1] = (
            IDiamondCut.FacetCut({
                facetAddress: address(liquidityFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: _generateSelectors("LiquidityFacet")
            })
        );
        diamondCut[2] = (
            IDiamondCut.FacetCut({
                facetAddress: address(loanFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: _generateSelectors("LoanFacet")
            })
        );
        diamondCut[3] = (
            IDiamondCut.FacetCut({
                facetAddress: address(vaultFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: _generateSelectors("VaultFacet")
            })
        );
        diamondCut[4] = (
            IDiamondCut.FacetCut({
                facetAddress: address(configurationFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: _generateSelectors("ConfigurationFacet")
            })
        );
        diamondCut[5] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dataProviderFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: _generateSelectors("DataProviderFacet")
            })
        );

        InitDiamond.Args memory args = InitDiamond.Args({
            initOwner: owner,
            seniorDepositTokenImpl: address(seniorDepositToken),
            juniorDepositTokenImpl: address(juniorDepositToken),
            vaultImpl: address(vault),
            weth9: address(weth)
        });

        IDiamondCut(address(voyage)).diamondCut(
            diamondCut,
            address(initDiamond),
            abi.encodeWithSelector(initDiamond.init.selector, args)
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
        paymaster.setTrustedForwarder(address(mockForwarder));
        // paymaster.setRelayHub(mockRelayHub);
        vm.stopPrank();
    }

    function _generateSelectors(string memory _facetName)
        internal
        returns (bytes4[] memory selectors)
    {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/gen_selectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function setupTest() internal {
        // infra
        vm.startPrank(owner);
        paymaster.setTrustedForwarder(address(mockForwarder));
        vm.deal(owner, 20000000 ether);
        weth.deposit{value: 10000000 ether}();
        ConfigurationFacet(address(voyage)).setGSNConfiguration(
            address(paymaster),
            address(mockForwarder)
        );
        // adapter

        // tokenization

        // reserve initialization
        LiquidityFacet(address(voyage)).initReserve(
            address(crab),
            address(weth),
            address(defaultReserveInterestRateStrategy),
            address(priceOracle)
        );

        uint liquidationBonus = 10500;
        uint incomeRatio = 0.5 * 1e4;
        uint optimalLiquidityRatio = 0.5 * 1e4;
        uint epoch = 30;
        uint term = 90;
        uint gracePeriod = 10;
        uint40 protocolFee = 200;
        uint maxStaleness = 10000;
        // uint baseRate = 0.2;

        // --- 105%
        ConfigurationFacet(address(voyage)).setLiquidationBonus(
            address(crab), 
            liquidationBonus
        );
        ConfigurationFacet(address(voyage)).setIncomeRatio(
            address(crab), 
            incomeRatio
        );
        ConfigurationFacet(address(voyage)).setOptimalLiquidityRatio(
            address(crab), 
            optimalLiquidityRatio
        );
        ConfigurationFacet(address(voyage)).setLoanParams(
            address(crab), 
            epoch, 
            term, 
            gracePeriod
        );
        LiquidityFacet(address(voyage)).activateReserve(address(crab));
        ConfigurationFacet(address(voyage)).setMaxTwapStaleness(
            address(crab), 
            maxStaleness
        );

        LiquidityFacet(address(voyage)).updateProtocolFee(owner, protocolFee);
        ConfigurationFacet(address(voyage)).updateMarketPlaceData(
            address(mockMarketPlace), 
            address(looksRareAdapter)
        );
        ConfigurationFacet(address(voyage)).updateMarketPlaceData(
            address(mockSeaport), 
            address(seaportAdapter)
        );

        (address senior, address junior) = DataProviderFacet(address(voyage)).getDepositTokens(address(crab));

        weth.approve(address(voyage), type(uint256).max);

        // vault initialization
        // --- create an empty vault
        bytes20 salt = bytes20(keccak256(abi.encodePacked("PwnedNoMore")));
        VaultFacet(address(voyage)).createVault(owner, salt);
        address deployedVault = DataProviderFacet(address(voyage)).getVault(owner);
        // --- fund vault for the first payment
        deployedVault.call{value: 100 ether}("");
        weth.transfer(deployedVault, 10 wei);
        weth.approve(deployedVault, type(uint256).max);

        // // the "todo delete" section, won't transcribe it till we need it.

        vm.stopPrank();
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {IDiamondLoupe} from "../../../contracts/shared/diamond/interfaces/IDiamondLoupe.sol";
import {OwnershipFacet} from "../../../contracts/shared/diamond/facets/OwnershipFacet.sol";
import {ConfigurationFacet} from "../../../contracts/voyage/facets/ConfigurationFacet.sol";
import {DataProviderFacet} from "../../../contracts/voyage/facets/DataProviderFacet.sol";
import {LiquidateFacet} from "../../../contracts/voyage/facets/LiquidateFacet.sol";
import {LiquidityFacet} from "../../../contracts/voyage/facets/LiquidityFacet.sol";
import {LoanFacet} from "../../../contracts/voyage/facets/LoanFacet.sol";
import {OracleFacet} from "../../../contracts/voyage/facets/OracleFacet.sol";
import {RepaymentFacet} from "../../../contracts/voyage/facets/RepaymentFacet.sol";
import {SecurityFacet} from "../../../contracts/voyage/facets/SecurityFacet.sol";
import {VaultFacet} from "../../../contracts/voyage/facets/VaultFacet.sol";
import {Voyage} from "../../../contracts/voyage/Voyage.sol";
import {JuniorDepositToken} from "../../../contracts/voyage/tokenization/JuniorDepositToken.sol";
import {SeniorDepositToken} from "../../../contracts/voyage/tokenization/SeniorDepositToken.sol";
import {Vault} from "../../../contracts/vault/Vault.sol";
import {WETH9} from "../../../contracts/mock/WETH9.sol";
import {IDiamondCut} from "../../../contracts/shared/diamond/interfaces/IDiamondCut.sol";
import {ILiquidityFacet} from "../../../contracts/voyage/interfaces/ILiquidityFacet.sol";
import {IConfigurationFacet} from "../../../contracts/voyage/interfaces/IConfigurationFacet.sol";
import {IDataProvider} from "../../../contracts/voyage/interfaces/IDataProvider.sol";
import {ILiquidateFacet} from "../../../contracts/voyage/interfaces/ILiquidateFacet.sol";
import {ILoanFacet} from "../../../contracts/voyage/interfaces/ILoanFacet.sol";
import {IOracleFacet} from "../../../contracts/voyage/interfaces/IOracleFacet.sol";
import {IRepaymentFacet} from "../../../contracts/voyage/interfaces/IRepaymentFacet.sol";
import {ISecurityFacet} from "../../../contracts/voyage/interfaces/ISecurityFacet.sol";
import {IVaultFacet} from "../../../contracts/voyage/interfaces/IVaultFacet.sol";
import {InitDiamond} from "../../../contracts/voyage/InitDiamond.sol";
import "hardhat/console.sol";

struct Snapshot {
    IDiamondLoupe.Facet[] facets;
    address init; // address of InitDiamondVx
    bytes initArgs; // abi encoded args to pass to InitDiamondVX
}

library Setup {
    function initFacets(address _initOwner) internal returns (address,address) {
        Voyage voyage = new Voyage(address(this));
        console.log("Setup#initFacets voyage address: ", address(voyage));
        JuniorDepositToken juniorDepositToken = new JuniorDepositToken();
        SeniorDepositToken seniorDepositToken = new SeniorDepositToken();
        Vault vault = new Vault();
        WETH9 weth9 = new WETH9();
        InitDiamond.Args memory args;
        args.initOwner = _initOwner;
        args.seniorDepositTokenImpl = address(juniorDepositToken);
        args.juniorDepositTokenImpl = address(seniorDepositToken);
        args.vaultImpl = address(vault);
        args.weth9 = address(weth9);
        bytes memory _calldata = abi.encodeWithSelector(
            InitDiamond.init.selector,
            args
        );
        address[] memory facetAddress = new address[](10);
        facetAddress[0] = address(new InitDiamond());
        facetAddress[1] = address(new ConfigurationFacet());
        facetAddress[2] = address(new DataProviderFacet());
        facetAddress[3] = address(new LiquidateFacet());
        facetAddress[4] = address(new LiquidityFacet());
        facetAddress[5] = address(new LoanFacet());
        facetAddress[6] = address(new OracleFacet());
        facetAddress[7] = address(new RepaymentFacet());
        facetAddress[8] = address(new SecurityFacet());
        facetAddress[9] = address(new VaultFacet());

        addFacetFunctions(voyage, facetAddress, _calldata);
        OwnershipFacet(address(voyage)).transferOwnership(_initOwner);

        return (address(voyage),address(weth9));
    }

    function addFacetFunctions(
        Voyage voyage,
        address[] memory facetAddress,
        bytes memory initData
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](9);

        // configuration facet
        bytes4[] memory configurationFunctionSelectors = new bytes4[](13);
        configurationFunctionSelectors[0] = IConfigurationFacet
            .setLiquidationBonus
            .selector;
        configurationFunctionSelectors[1] = IConfigurationFacet
            .setIncomeRatio
            .selector;
        configurationFunctionSelectors[2] = IConfigurationFacet
            .setOptimalLiquidityRatio
            .selector;
        configurationFunctionSelectors[3] = IConfigurationFacet
            .setMaxTwapStaleness
            .selector;
        configurationFunctionSelectors[4] = IConfigurationFacet
            .setLoanParams
            .selector;
        configurationFunctionSelectors[5] = IConfigurationFacet
            .setGSNConfiguration
            .selector;
        configurationFunctionSelectors[6] = IConfigurationFacet
            .setInterestRateStrategyAddress
            .selector;
        configurationFunctionSelectors[7] = IConfigurationFacet
            .updateMarketPlaceData
            .selector;
        configurationFunctionSelectors[8] = IConfigurationFacet
            .upgradeJuniorDepositTokenImpl
            .selector;
        configurationFunctionSelectors[9] = IConfigurationFacet
            .upgradeSeniorDepositTokenImpl
            .selector;
        configurationFunctionSelectors[10] = IConfigurationFacet
            .setOracleSigner
            .selector;
        configurationFunctionSelectors[11] = IConfigurationFacet
            .getOracleSigner
            .selector;
        configurationFunctionSelectors[12] = IConfigurationFacet
            .setTwapTolerance
            .selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[1],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: configurationFunctionSelectors
        });

        // dataProivder facet
        bytes4[] memory dataProviderFunctionSelectors = new bytes4[](11);
        dataProviderFunctionSelectors[0] = IDataProvider
            .getPoolConfiguration
            .selector;
        dataProviderFunctionSelectors[1] = IDataProvider.getPoolData.selector;
        dataProviderFunctionSelectors[2] = IDataProvider
            .getDepositTokens
            .selector;
        dataProviderFunctionSelectors[3] = IDataProvider.getVault.selector;
        dataProviderFunctionSelectors[4] = IDataProvider
            .getCollections
            .selector;
        dataProviderFunctionSelectors[5] = IDataProvider
            .getUserPoolData
            .selector;
        dataProviderFunctionSelectors[6] = IDataProvider
            .getCreditLineData
            .selector;
        dataProviderFunctionSelectors[7] = IDataProvider.getLoanDetail.selector;
        dataProviderFunctionSelectors[8] = IDataProvider.getRepayment.selector;
        dataProviderFunctionSelectors[9] = IDataProvider
            .pendingSeniorWithdrawals
            .selector;
        dataProviderFunctionSelectors[10] = IDataProvider
            .getProtocolFeeParam
            .selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[2],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: dataProviderFunctionSelectors
        });

        // liquidate facet
        bytes4[] memory liquidateFunctionSelectors = new bytes4[](1);
        liquidateFunctionSelectors[0] = ILiquidateFacet.liquidate.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[3],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: liquidateFunctionSelectors
        });

        // liquidity facet
        bytes4[] memory liquidityFunctionSelectors = new bytes4[](12);
        liquidityFunctionSelectors[0] = ILiquidityFacet.initReserve.selector;
        liquidityFunctionSelectors[1] = ILiquidityFacet
            .activateReserve
            .selector;
        liquidityFunctionSelectors[2] = ILiquidityFacet
            .deactivateReserve
            .selector;
        liquidityFunctionSelectors[3] = ILiquidityFacet
            .updateProtocolFee
            .selector;
        liquidityFunctionSelectors[4] = ILiquidityFacet
            .upgradePriceOracleImpl
            .selector;
        liquidityFunctionSelectors[5] = ILiquidityFacet.updateWETH9.selector;
        liquidityFunctionSelectors[6] = ILiquidityFacet.deposit.selector;
        liquidityFunctionSelectors[7] = ILiquidityFacet.withdraw.selector;
        liquidityFunctionSelectors[8] = ILiquidityFacet
            .getReserveStatus
            .selector;
        liquidityFunctionSelectors[9] = ILiquidityFacet.balance.selector;
        liquidityFunctionSelectors[10] = ILiquidityFacet.unbonding.selector;
        liquidityFunctionSelectors[11] = ILiquidityFacet
            .getReserveFlags
            .selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[4],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: liquidityFunctionSelectors
        });

        // loan facet
        bytes4[] memory loanFunctionSelectors = new bytes4[](8);
        loanFunctionSelectors[0] = ILoanFacet.previewBuyNowParams.selector;
        loanFunctionSelectors[1] = ILoanFacet.buyNow.selector;
        loanFunctionSelectors[2] = ILoanFacet.buyNowV2.selector;
        loanFunctionSelectors[3] = ILoanFacet.getVaultDebt.selector;
        loanFunctionSelectors[4] = ILoanFacet.principalBalance.selector;
        loanFunctionSelectors[5] = ILoanFacet.interestBalance.selector;
        loanFunctionSelectors[6] = ILoanFacet.seniorInterestBalance.selector;
        loanFunctionSelectors[7] = ILoanFacet.juniorInterestBalance.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[5],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loanFunctionSelectors
        });

        // oracle facet
        bytes4[] memory oracleFunctionSelectors = new bytes4[](1);
        oracleFunctionSelectors[0] = IOracleFacet.verifyMessage.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[6],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: oracleFunctionSelectors
        });

        // repayment facet
        bytes4[] memory repaymentFunctionSelectors = new bytes4[](1);
        repaymentFunctionSelectors[0] = IRepaymentFacet.repay.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[7],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: repaymentFunctionSelectors
        });

        // security facet
        bytes4[] memory securityFunctionSelectors = new bytes4[](13);
        securityFunctionSelectors[0] = ISecurityFacet.pause.selector;
        securityFunctionSelectors[1] = ISecurityFacet.unpause.selector;
        securityFunctionSelectors[2] = ISecurityFacet.grantRole.selector;
        securityFunctionSelectors[3] = ISecurityFacet
            .grantRolePermission
            .selector;
        securityFunctionSelectors[4] = ISecurityFacet
            .revokeRolePermission
            .selector;
        securityFunctionSelectors[5] = ISecurityFacet.grantPermission.selector;
        securityFunctionSelectors[6] = ISecurityFacet
            .authorizeConfigurator
            .selector;
        securityFunctionSelectors[7] = ISecurityFacet.revokePermission.selector;
        securityFunctionSelectors[8] = ISecurityFacet
            .isAuthorisedInbound
            .selector;
        securityFunctionSelectors[9] = ISecurityFacet
            .isAuthorisedOutbound
            .selector;
        securityFunctionSelectors[10] = ISecurityFacet.isAuthorised.selector;
        securityFunctionSelectors[11] = ISecurityFacet
            .isTrustedForwarder
            .selector;
        securityFunctionSelectors[12] = ISecurityFacet.paused.selector;
        cut[7] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[8],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: securityFunctionSelectors
        });

        // vault facet
        bytes4[] memory vaultFunctionSelectors = new bytes4[](12);
        vaultFunctionSelectors[0] = IVaultFacet.createVault.selector;
        vaultFunctionSelectors[1] = IVaultFacet.getVaultImpl.selector;
        vaultFunctionSelectors[2] = IVaultFacet.setVaultImpl.selector;
        vaultFunctionSelectors[3] = IVaultFacet.withdrawNFT.selector;
        vaultFunctionSelectors[4] = IVaultFacet.transferCurrency.selector;
        vaultFunctionSelectors[5] = IVaultFacet.wrapVaultETH.selector;
        vaultFunctionSelectors[6] = IVaultFacet.unwrapVaultETH.selector;
        vaultFunctionSelectors[7] = IVaultFacet.approveMarketplace.selector;
        vaultFunctionSelectors[8] = IVaultFacet
            .computeCounterfactualAddress
            .selector;
        vaultFunctionSelectors[9] = IVaultFacet.collectionInitialized.selector;
        vaultFunctionSelectors[10] = IVaultFacet.subVaultBeacon.selector;
        vaultFunctionSelectors[11] = IVaultFacet.getVaultAddr.selector;
        cut[8] = IDiamondCut.FacetCut({
            facetAddress: facetAddress[9],
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultFunctionSelectors
        });

        IDiamondCut(address(voyage)).diamondCut(cut, facetAddress[0], initData);
    }
}

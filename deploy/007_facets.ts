import { getWETH9 } from '@helpers/task-helpers/addresses';
import { ethers } from 'hardhat';
import { DeployFunction, Facet, FacetCut } from 'hardhat-deploy/types';
import { deployFacets, FacetCutAction, mergeABIs } from '../helpers/diamond';
import { log } from '../helpers/logger';

// These selectors are for DiamondCutFacet, DiamondLoupeFacet, and OwnershipFacet.
// When deciding which facets to remove, these should be excluded as they are part of the diamond standard.
// They are hardcoded in the constructor of the base Diamond contract.
const DEFAULT_SELECTORS = [
  '0x1f931c1c', // diamondCut((address,uint8,bytes4[])[],address,bytes)
  '0x7a0ed627', // facets()
  '0xadfca15e', // facetFunctionSelectors(address)
  '0x52ef6b2c', // facetAddresses()
  '0xcdffacc6', // facetAddress(bytes4)
  '0x01ffc9a7', // supportsInterface(bytes4)
  '0xf2fde38b', // transferOwnership(address)
  '0x8da5cb5b', // owner()
];

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { get, deploy, execute, save } = deployments;
  const { owner } = await getNamedAccounts();

  let changesDetected = false;
  // This only returns the bare diamond proxy.
  const diamond = await ethers.getContract('Voyage');
  const deployment = await get('Voyage');
  log.debug('diamond address: ', diamond.address);
  const existingFacets: Facet[] = await diamond.facets();
  log.debug('existing facets: %o', existingFacets);
  const existingSelectors: string[] = [];
  const selectorFacetMap: { [selector: string]: Facet } = {};
  for (const facet of existingFacets) {
    for (const selector of facet.functionSelectors) {
      existingSelectors.push(selector);
      selectorFacetMap[selector] = facet;
    }
  }

  const [facets, _, facetABIs] = await deployFacets(
    {
      name: 'SecurityFacet',
      from: owner,
      log: true,
    },
    {
      name: 'LiquidityFacet',
      from: owner,
      log: true,
    },
    {
      name: 'LoanFacet',
      from: owner,
      log: true,
    },
    {
      name: 'VaultFacet',
      from: owner,
      log: true,
    },
    {
      name: 'ConfigurationFacet',
      from: owner,
      log: true,
    },
    {
      name: 'DataProviderFacet',
      from: owner,
      log: true,
    },
    {
      name: 'PaymentsFacet',
      from: owner,
      log: true,
    },
    {
      name: 'MarketplaceAdapterFacet',
      from: owner,
      log: true,
    }
  );
  const newSelectors: string[] = facets.reduce<string[]>(
    (acc, { functionSelectors }) => [...acc, ...functionSelectors],
    []
  );
  const cuts: FacetCut[] = [];
  for (const facet of facets) {
    const add: string[] = [];
    const replace: string[] = [];
    for (const selector of facet.functionSelectors) {
      // selector is already available on the diamond
      if (existingSelectors.indexOf(selector) >= 0) {
        const currentHostFacet = selectorFacetMap[selector];
        if (
          currentHostFacet.facetAddress.toLowerCase() !==
          facet.facetAddress.toLowerCase()
        ) {
          replace.push(selector);
        }
      } else {
        add.push(selector);
      }
    }
    if (replace.length > 0) {
      changesDetected = true;
      cuts.push({
        facetAddress: facet.facetAddress,
        functionSelectors: replace,
        action: FacetCutAction.Replace,
      });
    }

    if (add.length > 0) {
      changesDetected = true;
      cuts.push({
        facetAddress: facet.facetAddress,
        functionSelectors: add,
        action: FacetCutAction.Add,
      });
    }
  }

  const del: string[] = [];
  for (const sel of existingSelectors) {
    log.debug('existing selector: %s', sel);
    // never delete default functions
    if (DEFAULT_SELECTORS.indexOf(sel) >= 0) {
      log.debug('not deleting default diamond function: %s', sel);
      continue;
    }
    if (newSelectors.indexOf(sel) === -1) {
      del.push(sel);
    }
  }

  if (del.length > 0) {
    changesDetected = true;
    cuts.unshift({
      facetAddress: ethers.constants.AddressZero,
      functionSelectors: del,
      action: FacetCutAction.Remove,
    });
  }

  if (changesDetected) {
    if (cuts.length > 0) {
      log.debug('Deploying InitDiamond');
      await deploy('InitDiamond', {
        from: owner,
        log: true,
        args: [],
      });

      const vaultImpl = await ethers.getContract('Vault');
      const seniorDepositImpl = await ethers.getContract('SeniorDepositToken');
      const juniorDepositImpl = await ethers.getContract('JuniorDepositToken');
      const weth9 = await getWETH9();

      const initDiamond = await ethers.getContract('InitDiamond');
      log.debug('Preparing InitDiamond call data');
      const initArgs = initDiamond.interface.encodeFunctionData('init', [
        {
          initOwner: owner,
          seniorDepositTokenImpl: seniorDepositImpl.address,
          juniorDepositTokenImpl: juniorDepositImpl.address,
          vaultImpl: vaultImpl.address,
          weth9,
        },
      ]);

      log.debug('Executing cuts: %o', cuts);
      await execute(
        'Voyage',
        {
          from: owner,
          log: true,
        },
        'diamondCut',
        cuts,
        initDiamond.address,
        initArgs
      );
    } else {
      log.debug('No facets to update for diamond');
    }
  }

  const mergedABI = mergeABIs([deployment.abi, ...facetABIs], {
    check: true,
    skipSupportsInterface: false,
  });
  await save('Voyage', {
    ...deployment,
    abi: mergedABI,
    facets,
  });
};

deployFn.dependencies = ['Diamond'];
deployFn.tags = ['Facets'];

export default deployFn;

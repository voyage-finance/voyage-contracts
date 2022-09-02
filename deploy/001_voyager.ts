import { ethers } from 'hardhat';
import { DeployFunction, Facet, FacetCut } from 'hardhat-deploy/types';
import { Voyage } from '@contracts';
import { deployFacets, FacetCutAction, mergeABIs } from '../helpers/diamond';
import { log } from '../helpers/logger';

// rinkeby relay hub
const DEFAULT_RELAY_HUB = '0x6650d69225CA31049DB7Bd210aE4671c0B1ca132';
// rinkeby forwarder
const DEFAULT_TRUSTED_FORWARDER = '0x83A54884bE4657706785D7309cf46B58FE5f6e8a';

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
  const { deploy, execute, getOrNull, save, getArtifact } = deployments;
  const { owner, treasury, forwarder } = await getNamedAccounts();

  const seniorDepositImpl = await deploy('SeniorDepositToken', {
    from: owner,
    log: true,
  });
  const juniorDepositImpl = await deploy('JuniorDepositToken', {
    from: owner,
    log: true,
  });
  await deploy('PriceOracle', {
    from: owner,
    log: true,
  });
  await deploy('LooksRareAdapter', {
    from: owner,
    log: true,
  });

  const diamondCutFacet = await deploy('DiamondCutFacet', {
    from: owner,
    log: true,
  });
  const diamondLoupeFacet = await deploy('DiamondLoupeFacet', {
    from: owner,
    log: true,
  });
  const ownershipFacet = await deploy('OwnershipFacet', {
    from: owner,
    log: true,
  });
  const weth9 = await deploy('WETH9', {
    from: owner,
    log: true,
  });
  await deploy('SeaportAdapter', {
    from: owner,
    log: true,
    args: [weth9.address],
  });
  const diamondABI: any[] = [];
  const diamondProxyArtifact = await getArtifact('Diamond');
  diamondABI.push(diamondProxyArtifact.abi);

  // This only returns the bare diamond proxy.
  let existingProxyDeployment = await getOrNull('VoyageDiamondProxy');
  let existingFacets: Facet[] = [];
  const existingSelectors: string[] = [];
  const selectorFacetMap: { [selector: string]: Facet } = {};
  if (existingProxyDeployment) {
    log.debug(
      'existing voyage diamond proxy %s: ',
      existingProxyDeployment?.address
    );
    // this returns the diamond with merged ABI.
    const diamond = await ethers.getContract('Voyage');
    log.debug('diamond address: ', diamond.address);
    existingFacets = await diamond.facets();
    log.debug('existing facets: %o', existingFacets);
  }

  let changesDetected = !existingProxyDeployment;
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
    if (!existingProxyDeployment) {
      log.debug('No existing diamond proxy found. Deploying a fresh diamond.');
      log.debug('Initialising with diamond cuts: %o', cuts);
      // TODO: check if there is already a diamond at this address, e.g., in case `deployments` folder was wiped.
      // if there is one, it can actually be re-used
      try {
        existingProxyDeployment = await deploy('VoyageDiamondProxy', {
          contract: 'contracts/voyage/Voyage.sol:Voyage',
          from: owner,
          log: true,
          args: [owner],
        });
        log.debug(
          'Deployed fresh diamond proxy at: ',
          existingProxyDeployment.address
        );
      } catch (err) {
        log.error(err);
        log.fatal('Failed to deploy diamond proxy.');
        process.exit(1);
      }
    }

    const mergedABI = mergeABIs([existingProxyDeployment!.abi, ...facetABIs], {
      check: true,
      skipSupportsInterface: false,
    });

    save('Voyage', {
      ...existingProxyDeployment,
      abi: mergedABI,
      facets,
    });

    const paymaster = await deploy('VoyagePaymaster', {
      from: owner,
      log: true,
      args: [existingProxyDeployment.address, weth9.address, treasury],
    });

    const RELAY_HUB = process.env.RELAY_HUB || DEFAULT_RELAY_HUB;
    await execute(
      'VoyagePaymaster',
      { from: owner, log: true },
      'setRelayHub',
      RELAY_HUB
    );
    log.info('set paymaster relay hub to %s', RELAY_HUB);

    const vaultImpl = await deploy('Vault', {
      from: owner,
      log: true,
      args: [],
    });

    const FORWARDER =
      process.env.NODE_ENV === 'test'
        ? forwarder
        : process.env.TRUSTED_FORWARDER || DEFAULT_TRUSTED_FORWARDER;
    await execute(
      'VoyagePaymaster',
      { from: owner, log: true },
      'setTrustedForwarder',
      FORWARDER
    );
    log.info('set paymaster forwarder to %s', FORWARDER);

    if (cuts.length > 0) {
      log.debug('Deploying InitDiamond');
      await deploy('InitDiamond', {
        from: owner,
        log: true,
        args: [],
      });
      const initDiamond = await ethers.getContract('InitDiamond');
      log.debug('Preparing InitDiamond call data');
      const initArgs = initDiamond.interface.encodeFunctionData('init', [
        {
          initOwner: owner,
          seniorDepositTokenImpl: seniorDepositImpl.address,
          juniorDepositTokenImpl: juniorDepositImpl.address,
          vaultImpl: vaultImpl.address,
          diamondCutFacet: diamondCutFacet.address,
          diamondLoupeFacet: diamondLoupeFacet.address,
          ownershipFacet: ownershipFacet.address,
          weth9: weth9.address,
          trustedForwarder: FORWARDER,
          paymaster: paymaster.address,
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
      log.debug(
        'No facets to update for diamond at %s',
        existingProxyDeployment.address
      );
    }

    if (vaultImpl.newlyDeployed) {
      await execute(
        'Voyage',
        { from: owner, log: true },
        'setVaultImpl',
        vaultImpl.address
      );
    }
  }
};

deployFn.tags = ['Voyage'];

export default deployFn;

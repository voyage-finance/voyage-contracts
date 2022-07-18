import { ethers } from 'hardhat';
import { DeployFunction, Facet, FacetCut } from 'hardhat-deploy/types';
import { deployFacets, FacetCutAction, mergeABIs } from '../helpers/diamond';
import { log } from '../helpers/logger';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, getOrNull, save, getArtifact } = deployments;
  const { owner } = await getNamedAccounts();

  const marginEscrowImpl = await deploy('MarginEscrow', {
    from: owner,
    log: true,
  });
  const creditEscrowImpl = await deploy('CreditEscrow', {
    from: owner,
    log: true,
  });
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
  const vaultFactory = await deploy('VaultFactory', {
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
      name: 'DiamondVersionFacet',
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
      name: 'CrabadaAdapterFacet',
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
      log.debug('Initialising with diamond cuts: %s', cuts);
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

    if (cuts.length > 0) {
      log.debug('Deploying InitDiamond');
      await deploy('InitDiamond', {
        from: owner,
        log: true,
        args: [],
        gasLimit: ethers.BigNumber.from('8000000'),
      });
      const initDiamond = await ethers.getContract('InitDiamond');
      log.debug('Preparing InitDiamond call data');
      const initArgs = initDiamond.interface.encodeFunctionData('init', [
        {
          initOwner: owner,
          marginEscrowImpl: marginEscrowImpl.address,
          creditEscrowImpl: creditEscrowImpl.address,
          seniorDepositTokenImpl: seniorDepositImpl.address,
          juniorDepositTokenImpl: juniorDepositImpl.address,
          vaultFactory: vaultFactory.address,
          diamondCutFacet: diamondCutFacet.address,
          diamondLoupeFacet: diamondLoupeFacet.address,
          ownershipFacet: ownershipFacet.address,
          weth9: weth9.address,
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
  }
};

deployFn.tags = ['Voyage'];

export default deployFn;

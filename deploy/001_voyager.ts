import { ethers } from 'hardhat';
import { DeployFunction, Facet, FacetCut } from 'hardhat-deploy/types';
import { deployFacets, FacetCutAction, mergeABIs } from '../helpers/diamond';
import { log } from '../helpers/logger';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, getOrNull, save } = deployments;
  const { owner } = await getNamedAccounts();
  const addressResolver = await deployments.get('AddressResolver');

  const diamondABI: any[] = [];

  // This only returns the bare diamond proxy.
  let existingProxyDeployment = await getOrNull('VoyagerDiamondProxy');
  let existingFacets: Facet[] = [];
  const existingSelectors: string[] = [];
  const selectorFacetMap: { [selector: string]: Facet } = {};
  if (existingProxyDeployment) {
    log.debug(
      'existing voyage diamond proxy %s: ',
      existingProxyDeployment?.address
    );
    // this returns the diamond with merged ABI.
    const diamond = await ethers.getContract('Voyager');
    existingFacets = await diamond.facets();
    log.debug('existing facets: %o', existingFacets);
    diamondABI.push(existingProxyDeployment.abi);
  }

  let changesDetected = !existingProxyDeployment;
  for (const facet of existingFacets) {
    for (const selector of facet.functionSelectors) {
      existingSelectors.push(selector);
      selectorFacetMap[selector] = facet;
    }
  }

  await deploy('SafeMath', {
    contract: '@openzeppelin/contracts/utils/math/SafeMath.sol:SafeMath',
    from: owner,
    log: true,
  });
  await deploy('WadRayMath', { from: owner, log: true });

  const [facets, _, facetABIs] = await deployFacets({
    name: 'VoyageDataProviderFacet',
    from: owner,
    log: true,
  });
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
        existingProxyDeployment = await deploy('VoyagerDiamondProxy', {
          contract: 'Voyager',
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

    save('Voyager', {
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
      });
      const initDiamond = await ethers.getContract('InitDiamond');
      log.debug('Preparing InitDiamond call data');
      const initArgs = initDiamond.interface.encodeFunctionData('init', [
        {
          addressResolver: addressResolver.address,
        },
      ]);

      log.debug('Executing cuts: %o', cuts);
      await execute(
        'Voyager',
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

  await execute(
    'Voyager',
    { from: owner, log: true },
    'setAddressResolverAddress',
    addressResolver.address
  );
};

deployFn.dependencies = ['AddressResolver'];
deployFn.tags = ['Voyager'];

export default deployFn;

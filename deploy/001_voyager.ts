import { ethers } from 'hardhat';
import { DeployFunction, Facet, FacetCut } from 'hardhat-deploy/types';
import pino from 'pino';
import pretty from 'pino-pretty';
import { mergeABIs, FacetCutAction, deployFacets } from '../helpers/diamond';

const logLevel = process.env.DEBUG === 'true' ? 'debug' : 'info';
const log = pino(
  {
    level: logLevel,
  },
  pretty({
    colorize: true,
    singleLine: true,
  })
);
log.level = logLevel;

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, getOrNull, save } = deployments;
  const { owner } = await getNamedAccounts();

  const diamondABI: any[] = [];

  // This only returns the bare diamond proxy.
  let existingProxyDeployment = await getOrNull('VoyageDiamondProxy');
  let existingFacets: Facet[] = [];
  const existingSelectors: string[] = [];
  const selectorFacetMap: { [selector: string]: Facet } = {};
  if (existingProxyDeployment) {
    log.debug(
      'existing voyage diamond proxy: ',
      existingProxyDeployment?.address
    );
    // this returns the diamond with merged ABI.
    const diamond = await ethers.getContract('Voyage');
    existingFacets = await diamond.facets();
    log.debug('existing facets:', existingFacets);
    diamondABI.push(existingProxyDeployment.abi);
  }

  let changesDetected = !existingProxyDeployment;
  for (const facet of existingFacets) {
    for (const selector of facet.functionSelectors) {
      existingSelectors.push(selector);
      selectorFacetMap[selector] = facet;
    }
  }

  const [facets, _, facetABIs] = await deployFacets();
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
      log.debug('Initialising with diamond cuts: ', cuts);
      // TODO: check if there is already a diamond at this address, e.g., in case `deployments` folder was wiped.
      // if there is one, it can actually be re-used
      try {
        existingProxyDeployment = await deploy('VoyagerDiamondProxy', {
          contract: 'Voyager',
          from: owner,
          log: true,
          args: [cuts, { owner }],
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
    } else {
      if (cuts.length > 0) {
        log.debug('Executing upgrade with cuts: ', cuts);
        await execute(
          'Voyager',
          {
            from: owner,
            log: true,
          },
          'diamondCut',
          cuts,
          // TODO: might have initialisation data here.
          ethers.constants.AddressZero,
          ethers.constants.HashZero
        );
      } else {
        log.debug(
          'No facets to update for diamond at ',
          existingProxyDeployment.address
        );
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
  }

  const AddressResolver = await deployments.get('AddressResolver');
  await execute(
    'Voyager',
    { from: owner, log: true },
    'setAddressResolverAddress',
    AddressResolver.address
  );
};

deployFn.dependencies = ['AddressResolver'];
deployFn.tags = ['Voyager'];

export default deployFn;

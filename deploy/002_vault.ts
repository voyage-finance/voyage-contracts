import { ethers } from 'hardhat';
import { DeployFunction, Facet, FacetCut } from 'hardhat-deploy/types';
import { deployFacets, FacetCutAction, mergeABIs } from '../helpers/diamond';
import { log } from '../helpers/logger';
import { Vault } from '@contracts';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, getOrNull, save, getArtifact } = deployments;
  const { owner } = await getNamedAccounts();
  const voyage = await deployments.get('Voyage');
  const weth9 = await deployments.get('WETH9');

  const diamondABI: any[] = [];
  const diamondProxyArtifact = await getArtifact('VersionedDiamond');
  diamondABI.push(diamondProxyArtifact.abi);

  // This only returns the bare diamond proxy.
  let existingProxyDeployment = await getOrNull('VaultDiamondProxy');
  let existingFacets: Facet[] = [];
  const existingSelectors: string[] = [];
  const selectorFacetMap: { [selector: string]: Facet } = {};
  if (existingProxyDeployment) {
    log.debug(
      'existing vault diamond proxy %s: ',
      existingProxyDeployment?.address
    );
    // this returns the diamond with merged ABI.
    const diamond = await ethers.getContract('Vault');
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
      name: 'VaultAssetFacet',
      from: owner,
      log: true,
    },
    {
      name: 'VaultDataFacet',
      from: owner,
      log: true,
    },
    {
      name: 'VaultExternalFacet',
      from: owner,
      log: true,
    },
    {
      name: 'VaultManageFacet',
      from: owner,
      log: true,
    },
    {
      name: 'VaultMarginFacet',
      from: owner,
      log: true,
    },
    {
      name: 'PaymentsFacet',
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
      log.info('owner: %s', owner);
      log.info('voyage: %s', voyage.address);
      try {
        existingProxyDeployment = await deploy('VaultDiamondProxy', {
          contract: 'contracts/vault/Vault.sol:Vault',
          from: owner,
          log: true,
        });
        log.info(
          'Deployed fresh diamond proxy at: %s',
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

    save('Vault', {
      ...existingProxyDeployment,
      abi: mergedABI,
      facets,
    });

    if (cuts.length > 0) {
      await deploy('VaultInitDiamond', {
        from: owner,
        log: true,
        args: [],
        gasLimit: ethers.BigNumber.from('8000000'),
      });
      const initDiamond = await ethers.getContract('VaultInitDiamond');
      log.debug('Preparing InitDiamond call data');
      const initArgs = initDiamond.interface.encodeFunctionData('init', [
        {
          initOwner: owner,
        },
      ]);

      log.info('Executing registerUpgrade');
      await execute(
        'Voyage',
        {
          from: owner,
          log: true,
        },
        'registerUpgrade',
        initDiamond.address,
        initArgs,
        cuts
      );

      const vault = await ethers.getContract<Vault>('Vault');

      log.info('Executing setVaultBeacon');
      await execute(
        'Voyage',
        {
          from: owner,
          log: true,
        },
        'setVaultBeacon',
        vault.address
      );
    } else {
      log.debug(
        'No facets to update for diamond at %s',
        existingProxyDeployment.address
      );
    }
  }
};

deployFn.tags = ['Vault'];
deployFn.dependencies = ['Voyage'];

export default deployFn;

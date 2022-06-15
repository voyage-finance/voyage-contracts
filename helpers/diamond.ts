import { Fragment, FunctionFragment, Interface } from '@ethersproject/abi';
import { deployments, getNamedAccounts } from 'hardhat';
import { ABI, DeployOptions, DeployResult, Facet } from 'hardhat-deploy/types';
const { deploy } = deployments;

export enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

/**
 * Extracts function selectors (4byte hash) from a given ABI.
 * @param abi - array of ABI fragments
 * @returns array of function selectors
 */
export const getSelectors = (abi: any[]): string[] => {
  const selectors: string[] = [];
  for (const elem of abi) {
    if (elem.type === 'function') {
      const sel = Interface.getSighash(FunctionFragment.from(elem));
      selectors.push(sel);
    }
  }

  return selectors;
};

/**
 * Takes a list of ABIs and merges them. Used for product a unified Diamonad ABI.
 *
 * @param abis - an array of contract ABIs
 * @param options - options
 * @returns merged ABI
 */
export function mergeABIs(
  abis: any[][],
  options: { check: boolean; skipSupportsInterface: boolean }
): any[] {
  if (abis.length === 0) {
    return [];
  }
  const result: any[] = JSON.parse(JSON.stringify(abis[0]));
  for (let i = 1; i < abis.length; i++) {
    const abi = abis[i];
    for (const fragment of abi) {
      const newEthersFragment = Fragment.from(fragment);
      // TODO constructor special handling ?
      const foundSameSig = result.find((v) => {
        const existingEthersFragment = Fragment.from(v);
        if (v.type !== fragment.type) {
          return false;
        }
        if (!existingEthersFragment) {
          return v.name === fragment.name; // TODO fallback and receive hanlding
        }

        if (
          existingEthersFragment.type === 'constructor' ||
          newEthersFragment.type === 'constructor'
        ) {
          return existingEthersFragment.name === newEthersFragment.name;
        }

        if (newEthersFragment.type === 'function') {
          return (
            Interface.getSighash(existingEthersFragment as FunctionFragment) ===
            Interface.getSighash(newEthersFragment as FunctionFragment)
          );
        } else if (newEthersFragment.type === 'event') {
          return existingEthersFragment.format() === newEthersFragment.format();
        } else {
          return v.name === fragment.name; // TODO fallback and receive hanlding
        }
      });
      if (foundSameSig) {
        if (
          options.check &&
          !(
            options.skipSupportsInterface &&
            fragment.name === 'supportsInterface'
          )
        ) {
          if (fragment.type === 'function') {
            throw new Error(
              `function "${fragment.name}" will shadow "${foundSameSig.name}". Please update code to avoid conflict.`
            );
          }
        }
      } else {
        result.push(fragment);
      }
    }
  }

  return result;
}

type FacetDeploymentOptions = { name: string } & Partial<
  Pick<DeployOptions, 'contract' | 'args' | 'libraries' | 'from' | 'log'>
>;

export const DEFAULT_FACETS: string[] = [
  'DiamondCutFacet',
  'DiamondLoupeFacet',
  'OwnershipFacet',
];

async function getDefaultABIs() {
  const artifacts = await Promise.all(
    DEFAULT_FACETS.map((facetName) => deployments.getArtifact(facetName))
  );
  return artifacts.map(({ abi }) => abi);
}

export async function deployFacets(
  ...facetDeployments: FacetDeploymentOptions[]
): Promise<[Facet[], DeployResult[], ABI[]]> {
  const { owner } = await getNamedAccounts();
  const cuts: Facet[] = [];
  const abis: any[][] = await getDefaultABIs();
  const deployments: DeployResult[] = [];

  for (const facet of facetDeployments) {
    const { name, contract, from, ...options } = facet;
    const res = await deploy(name, {
      ...options,
      contract: contract ?? name,
      from: from ?? owner,
      deterministicDeployment: true,
    });
    deployments.push(res);
    cuts.push({
      facetAddress: res.address,
      functionSelectors: getSelectors(res.abi),
    });
    abis.push(res.abi);
  }

  return [cuts, deployments, abis];
}

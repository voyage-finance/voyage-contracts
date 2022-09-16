import { LOOKS_ADDRESS } from '@helpers/constants';
import { ChainID, ExternalChainID, Marketplace, Token } from '@helpers/types';
import { CROSS_CHAIN_SEAPORT_ADDRESS } from '@opensea/seaport-js/lib/constants';
import { HRE } from './hre';

export const externalContracts: Record<number, Record<string, string>> = {
  [ChainID.Mainnet]: {
    [Marketplace.Looks]: '0x59728544B08AB483533076417FbBB2fD0B17CE3a',
    [Marketplace.Seaport]: CROSS_CHAIN_SEAPORT_ADDRESS,
    [Token.WETH9]: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
  },
  [ChainID.Rinkeby]: {
    [Marketplace.Looks]: '0x1AA777972073Ff66DCFDeD85749bDD555C0665dA',
    [Marketplace.Seaport]: CROSS_CHAIN_SEAPORT_ADDRESS,
    [Token.WETH9]: '0xc778417E063141139Fce010982780140Aa0cD5Ab',
  },
  [ChainID.Goerli]: {
    [Marketplace.Looks]: '0xD112466471b5438C1ca2D218694200e49d81D047',
    [Marketplace.Seaport]: CROSS_CHAIN_SEAPORT_ADDRESS,
    [Token.WETH9]: '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6',
  },
};

export async function getExternalContracts() {
  const chainId = parseInt(await HRE.getChainId());
  return externalContracts[chainId];
}

export async function getMarketplaceAdapterConfiguration() {
  const { ethers } = HRE;
  const chainId = parseInt(await HRE.getChainId());
  if (chainId === ChainID.Hardhat && !process.env.HARDHAT_DEPLOY_FORK)
    return [];
  const looksAdapter = await ethers.getContract('LooksRareAdapter');
  const seaportAdapter = await ethers.getContract('SeaportAdapter');
  return [
    {
      marketplace: LOOKS_ADDRESS[chainId as ExternalChainID],
      adapter: looksAdapter.address,
    },
    {
      marketplace: CROSS_CHAIN_SEAPORT_ADDRESS,
      adapter: seaportAdapter.address,
    },
  ];
}

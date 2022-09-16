import { BigNumber } from 'ethers';
import { Voyage, PriceOracle } from '@contracts';
import { HRE } from './hre';

export interface AdapterConfiguration {
  marketplace: string;
  adapter: string;
}

export async function setMarketplaceAdapters(configs: AdapterConfiguration[]) {
  const voyage = await HRE.ethers.getContract<Voyage>('Voyage');
  const receipts = [];
  for (const config of configs) {
    const { marketplace, adapter } = config;
    const tx = await voyage.updateMarketPlaceData(marketplace, adapter);
    const receipt = await tx.wait();
    receipts.push(receipt);
  }

  return receipts;
}

export interface TwapConfiguration {
  collection: string;
  twap: BigNumber;
}

export async function setTwap({ collection, twap }: TwapConfiguration) {
  const oracle = await HRE.ethers.getContract<PriceOracle>('PriceOracle');
  const tx = await oracle.updateTwap(collection, twap);
  await tx.wait();
}

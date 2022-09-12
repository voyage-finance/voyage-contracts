import { BigNumber } from 'ethers';
import { Voyage, PriceOracle } from '@contracts';
import { HRE } from './hre';

export interface AdapterConfiguration {
  marketplace: string;
  adapter: string;
}

export async function setMarketplaceAdapters(config: AdapterConfiguration[]) {
  const voyage = await HRE.ethers.getContract<Voyage>('Voyage');
  await Promise.all(
    config.map(async ({ marketplace, adapter }) => {
      const tx = await voyage.updateMarketPlaceData(marketplace, adapter);
      await tx.wait();
    })
  );
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

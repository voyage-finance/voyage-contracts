import { Voyage } from '@contracts';
import { task, types } from 'hardhat/config';

task('dev:set-twap-staleness', 'Sets the twap staleness')
  .addOptionalParam('collection', 'Address of the collection to set.')
  .addOptionalParam(
    'threshold',
    'Maximum staleness threshold',
    6 * 60 * 60,
    types.int
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const mc = await ethers.getContract('Crab');
    const { collection = mc.address, threshold } = params;
    console.log(`setting max staleness for ${collection} to ${threshold}`);
    const tx = await voyage.setMaxTwapStaleness(collection, threshold);
    await tx.wait();
    const res = await voyage.getMaxTwapStaleness(collection);
    console.log('max staleness: ', res.toString());
  });

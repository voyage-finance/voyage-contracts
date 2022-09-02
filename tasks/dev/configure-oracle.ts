import { setTwap } from '@helpers/task-helpers/configuration';
import { task, types } from 'hardhat/config';

task('dev:configure-oracle', 'Sets the twap for the given collection.')
  .addOptionalParam('collection', 'The collection to update twap for')
  .addOptionalParam('twap', 'The twap to set', '1', types.string)
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const mc = await ethers.getContract('Crab');
    const { collection = mc.address, twap } = params;
    await setTwap({ collection, twap: ethers.utils.parseEther(twap) });
    console.log(`Set twap for collection ${collection} to ${twap} ETH`);
  });

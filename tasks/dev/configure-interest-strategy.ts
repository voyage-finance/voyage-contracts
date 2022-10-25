import { COLLECTION } from '@helpers/configuration';
import { task, types } from 'hardhat/config';
import { Voyage } from '@contracts';

task('dev:configure-interest-strategy', 'Sets the twap for the given collection.')
  .addOptionalParam('collection', 'The collection to update twap for')
  .addOptionalParam('strategy', 'The interest rate strategy address')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { collection = COLLECTION, strategy = await (await ethers.getContract('DefaultReserveInterestRateStrategy')).address } = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    await voyage.setInterestRateStrategyAddress(collection,strategy);
    
  });

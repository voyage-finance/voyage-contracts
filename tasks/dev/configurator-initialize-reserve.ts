import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task('dev:configurator-initialize-reserve', 'Initializes a reserve.')
  .addOptionalParam('collection', 'The collections to initialize. Defaults to Mock Crab')
  .addOptionalParam('currency', 'The currency that this collection supports. Defaults to mock weth')
  .setAction(async (params, hre) => {
   
  });

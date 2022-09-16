import { setHRE } from '@helpers/task-helpers/hre';
import { ChainID, Networks } from '@helpers/types';
import { task } from 'hardhat/config';

task('set-hre').setAction(async (_, hre) => {
  // this means that the currently running hardhat instance is a fork of another chain.
  if (
    hre.network.name === 'localhost' &&
    hre.network.config.chainId &&
    hre.network.config.chainId !== 31337
  ) {
    const forkOf = Networks[hre.network.config.chainId as ChainID];
    process.env.HARDHAT_DEPLOY_FORK = forkOf;
  }
  setHRE(hre);
});

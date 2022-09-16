import { task } from 'hardhat/config';

task('tenderly:bootstrap', 'Bootstraps a tenderly fork').setAction(
  async (_, hre) => {
    await hre.run('set-hre');
    console.log('Funding default users\n');
    await hre.run('tenderly:fund-accounts');
    console.log('Bootstrapping reserves\n');
    await hre.run('dev:bootstrap');
  }
);

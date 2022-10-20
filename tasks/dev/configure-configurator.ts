import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task('dev:configure-configurator', 'Sets configurator')
  .addOptionalParam('configurator', 'The configurator address.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const voyageReserveConfigurator = await ethers.getContract(
      'VoyageReserveConfigurator'
    );
    const { configurator = voyageReserveConfigurator.address } = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const tx = await voyage.authorizeConfigurator(configurator);
    await tx.wait();
  });

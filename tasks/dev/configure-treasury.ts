import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task('dev:configure-treasury', 'Set treasury address and take rate')
  .addOptionalParam(
    'treasury',
    'The treasury address. Defaults to deployer multisig wallet'
  )
  .addOptionalParam('takeRate', 'The take rate. Defaults to 100(1%)')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const {
      treasury = '0x28178038f7b235b3F6DB3995C1B70D479918Fab8',
      takeRate = 100,
    } = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const tx = await voyage.updateProtocolFee(treasury, takeRate);
    await tx.wait();
  });

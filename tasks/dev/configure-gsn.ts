import { Voyage } from '@contracts';
import { getTrustedForwarder } from '@helpers/task-helpers/addresses';
import { task } from 'hardhat/config';

task('dev:configure-gsn', 'Sets trustedForwarder and voyagePaymaster')
  .addOptionalParam('forwarder', 'The forwarder address.')
  .addOptionalParam('paymaster', 'The paymaster address')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const defaultForwarder = await getTrustedForwarder();
    const defaultPaymaster = await ethers.getContract('VoyagePaymaster');
    const {
      forwarder = defaultForwarder,
      paymaster = defaultPaymaster.address,
    } = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const tx = await voyage.setGSNConfiguration(paymaster, forwarder);
    await tx.wait();
  });

import { VoyagePaymaster } from '@contracts';
import { task } from 'hardhat/config';

task('dev:withdraw-from-relayhub', 'Withdraw funds from relay hub')
  .addOptionalParam('target', 'The target to receive the withdrawal')
  .addOptionalParam('amount', 'The amount to withdrawal')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { target, amount } = params;
    const paymaster = await ethers.getContract<VoyagePaymaster>(
      'VoyagePaymaster'
    );
    const tx = await paymaster.withdrawRelayHubDepositTo(amount, target);
    await tx.wait();
  });

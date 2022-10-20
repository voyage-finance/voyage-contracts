import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task(
  'dev:configure-jd-impl',
  'Set the junior deposit token implementation to the current deployed one.'
)
  .addOptionalParam(
    'sender',
    'The sender of the transaction. Defaults to owner.'
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { sender } = params;
    const { owner } = await hre.getNamedAccounts();
    const signer = await ethers.getSigner(sender ?? owner);
    const voyage = await ethers.getContract<Voyage>('Voyage', signer);
    const juniorDepositToken = await ethers.getContract('JuniorDepositToken');
    const tx = await voyage.upgradeJuniorDepositTokenImpl(
      juniorDepositToken.address
    );
    const receipt = await tx.wait();
    console.log(
      `Set junior deposit implementation to ${juniorDepositToken.address}`
    );
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

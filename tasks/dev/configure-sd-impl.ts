import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task(
  'dev:configure-sd-impl',
  'Set the senior deposit token implementation to the current deployed one.'
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
    const seniorDepositToken = await ethers.getContract('SeniorDepositToken');
    const tx = await voyage.upgradeSeniorDepositTokenImpl(
      seniorDepositToken.address
    );
    const receipt = await tx.wait();
    console.log(
      `Set senior deposit implementation to ${seniorDepositToken.address}`
    );
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

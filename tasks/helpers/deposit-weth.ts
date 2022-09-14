import { WETH9 } from '@contracts';
import { getWETH9 } from '@helpers/task-helpers/addresses';
import { task, types } from 'hardhat/config';

task('dev:deposit-weth', 'Deposits WETH')
  .addOptionalParam(
    'amount',
    'The amount of ETH to wrap.',
    '10000',
    types.string
  )
  .addOptionalParam('sender', 'The account to use')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const { amount, sender } = params;
    const signer = await ethers.getSigner(sender ?? owner);
    const weth9Address = await getWETH9();
    const weth9 = await ethers.getContractAt<WETH9>(
      'WETH9',
      weth9Address,
      signer
    );
    const tx = await weth9.deposit({ value: ethers.utils.parseEther(amount) });
    const receipt = await tx.wait();
    console.log(`${signer.address} Deposited ${amount} ETH to WETH`);
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

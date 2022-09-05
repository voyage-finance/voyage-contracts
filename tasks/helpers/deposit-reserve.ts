import { deposit } from '@helpers/task-helpers/liquidity';
import { Tranche } from '@helpers/types';
import { task, types } from 'hardhat/config';

task('dev:deposit-reserve', 'deposits to the specified reserve')
  .addOptionalParam('reserve', 'The reserve to deposit to.')
  .addOptionalParam(
    'tranche',
    'The tranche to deposit to.',
    Tranche.Senior,
    types.int
  )
  .addOptionalParam('amount', 'The amount to be deposited in ETH.')
  .addOptionalParam('sender', 'The sender to use. Defaults to first account.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const collection = await ethers.getContract('Crab');
    const {
      reserve = collection.address,
      tranche,
      sender = owner,
      amount,
    } = params;
    await deposit(reserve, tranche, ethers.utils.parseEther(amount), sender);
    console.log(`Deposited ${amount} to tranche ${tranche}`);
  });

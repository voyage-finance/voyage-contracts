import { deposit } from '@helpers/task-helpers/liquidity';
import { task } from 'hardhat/config';

enum Tranche {
  Junior,
  Senior,
}

task('dev:deposit-reserve', 'deposits to the specified reserve')
  .addOptionalParam('reserve', 'The reserve to deposit to.')
  .addOptionalParam('tranche', 'The tranche to deposit to.')
  .addOptionalParam('amount', 'The amount to be deposited in ETH.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const collection = await ethers.getContract('Crab');
    const {
      reserve = collection.address,
      tranche = Tranche.Senior,
      amount,
    } = params;
    await deposit(reserve, tranche, ethers.utils.parseEther(amount), owner);
    console.log(`Deposited ${amount} to tranche ${tranche}`);
  });

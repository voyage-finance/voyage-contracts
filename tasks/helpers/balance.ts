import { Voyage } from '@contracts';
import { formatWad } from '@helpers/math';
import { task } from 'hardhat/config';

enum Tranche {
  Junior,
  Senior,
}

task('dev:balance', 'prints balance in pool')
  .addOptionalParam('reserve', 'The reserve to check.')
  .addOptionalParam('account', 'The account to check.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const collection = await ethers.getContract('Crab');
    const { owner } = await getNamedAccounts();
    const { reserve = collection.address, account = owner } = params;
    const juniorBalance = await voyage.balance(
      reserve,
      account,
      Tranche.Junior
    );
    const seniorBalance = await voyage.balance(
      reserve,
      account,
      Tranche.Senior
    );
    console.log(`balance in junior tranche: ${formatWad(juniorBalance)}`);
    console.log(`balance in senior tranche: ${formatWad(seniorBalance)}`);
  });

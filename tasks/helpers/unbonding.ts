import { Voyage } from '@contracts';
import { formatWad } from '@helpers/math';
import { task } from 'hardhat/config';

task('dev:unbonding', 'prints current unbonding information.')
  .addOptionalParam('reserve', 'The reserve to check.')
  .setAction(async (params, hre) => {
    const { ethers, getNamedAccounts } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const collection = await ethers.getContract('Crab');
    const { owner } = await getNamedAccounts();
    const { reserve = collection.address } = params;
    const unbonding = await voyage.unbonding(reserve, owner);
    console.log('unbonding amount: ', formatWad(unbonding));
  });

import { task } from 'hardhat/config';
import { SeniorDepositToken, Voyage } from '@contracts';

task('dev:claim', 'Claims unbonding amount')
  .addOptionalParam('reserve', 'The reserve to claim from.')
  .setAction(async (params, hre) => {
    const { ethers } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const collection = await ethers.getContract('Crab');
    const { reserve = collection.address } = params;
    const [seniorVTokenAddress] = await voyage.getDepositTokens(reserve);
    const vToken = await ethers.getContractAt<SeniorDepositToken>(
      'SeniorDepositToken',
      seniorVTokenAddress
    );
    const tx = await vToken.claim();
    await tx.wait();
    console.log('claimed tokens.');
  });

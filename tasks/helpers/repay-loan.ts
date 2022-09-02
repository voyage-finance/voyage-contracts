import { Voyage } from '@contracts';
import { task, types } from 'hardhat/config';

task(
  'dev:repay-loan',
  'Makes a repayment for a given vault, collection and loan id'
)
  .addPositionalParam('loanId', 'The loan id to pay up.', undefined, types.int)
  .addOptionalParam(
    'vault',
    'The vault to make repayment for. Defaults to owner vault.'
  )
  .addOptionalParam('collection', 'The collection. Default to Mocked Crab.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const defaultCollection = await ethers.getContract('Crab');
    const defaultVault = await voyage.getVault(owner);
    const {
      vault = defaultVault,
      collection = defaultCollection.address,
      loanId,
    } = params;
    const tx = await voyage.repay(collection, loanId, vault);
    const receipt = await tx.wait();
    console.log(
      `Repaid loanId ${loanId} in reserve ${collection} for vault ${vault}`
    );
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

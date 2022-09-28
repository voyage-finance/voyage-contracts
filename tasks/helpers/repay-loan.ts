import { Voyage } from '@contracts';
import { task, types } from 'hardhat/config';

task(
  'dev:repay-loan',
  'Makes a repayment for a given vault, collection and loan id'
)
  .addOptionalParam('sender', 'The account doing the repayment.')
  .addParam('loanid', 'The loan id to pay up.', undefined, types.int)
  .addOptionalParam('collection', 'The collection. Default to Mocked Crab.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const defaultCollection = await ethers.getContract('Crab');
    const {
      sender = owner,
      collection = defaultCollection.address,
      loanid,
    } = params;
    const signer = await ethers.getSigner(sender);
    const voyage = await ethers.getContract<Voyage>('Voyage', signer);
    const vault = await voyage.getVault(sender);
    const tx = await voyage.repay(collection, loanid, vault);
    const receipt = await tx.wait();
    console.log(
      `Repaid loanId ${loanid} in reserve ${collection} for vault ${vault}`
    );
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

import { task } from 'hardhat/config';
import { Voyage } from '@contracts';

task('dev:withdraw-nft', 'Withdraw nft from a vault')
  .addOptionalParam('collection', 'The collection address')
  .addPositionalParam('to', 'The address that asset would be transferred to')
  .addOptionalParam('tokenId', 'The token id to withdraw')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const mc = await ethers.getContract('Crab');
    const { collection = mc.address, to = owner, tokenId = 2519} = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    let vaultAddress = await voyage.getVault(owner);
    await voyage.withdrawNFT(vaultAddress, collection, owner,tokenId);
  });

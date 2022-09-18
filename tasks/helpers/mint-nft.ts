import { Crab } from '@contracts';
import { task } from 'hardhat/config';

task('dev:mint-nft', 'Mint nft for main account')
  .addParam('id', 'The tokenId')
  .addOptionalParam('count', 'Address of the collection.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { owner } = await hre.getNamedAccounts();
    const crab = await hre.ethers.getContract<Crab>('Crab');

    const { id, count = 1 } = params;
    const end = Number(id) + Number(count);

    for (let i = id; i <= end; i++) {
      const tx = await crab.safeMint(owner, i);
      console.log(`Minted token #${i} for ${owner} tx.hash = ${tx.hash}`);
    }
  });

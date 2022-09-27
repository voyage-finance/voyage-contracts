import { COLLECTION, LOOKS_RARE } from '@helpers/configuration';
import { task } from 'hardhat/config';
import { Voyage } from '@contracts';

task('dev:approve-marketplace', 'Approve marketplace on weth for vaule')
  .addOptionalParam('marketplace', 'The marketplace address')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const { marketplace = LOOKS_RARE} = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    let vaultAddress = await voyage.getVault(owner);
    await voyage.approveMarketplace(vaultAddress, marketplace, false);
  });

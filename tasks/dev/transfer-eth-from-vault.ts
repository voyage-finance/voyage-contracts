import { task } from 'hardhat/config';
import { Voyage } from '@contracts';

task('dev:transfer-eth-from-vault', 'Transfer eth out of vault')
  .addOptionalParam('to', 'The address that funds would be transferred to')
  .addOptionalParam('amount', 'The token amount')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const { to = owner, amount} = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    let vaultAddress = await voyage.getVault(owner);
    await voyage.transferETH(vaultAddress, to,amount);
  });

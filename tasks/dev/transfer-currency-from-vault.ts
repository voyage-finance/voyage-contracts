import { task } from 'hardhat/config';
import { Voyage } from '@contracts';
import { getWETH9 } from '@helpers/task-helpers/addresses';

task('dev:transfer-currency-from-vault', 'Transfer currency out of vault')
  .addOptionalParam('currency', 'The currency aka ERC20 token address')
  .addOptionalParam('to', 'The address that funds would be transferred to')
  .addOptionalParam('amount', 'The token amount')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const { currency = await getWETH9(), to = owner, amount} = params;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    let vaultAddress = await voyage.getVault(owner);
    await voyage.transferCurrency(vaultAddress, currency, to,amount);
  });

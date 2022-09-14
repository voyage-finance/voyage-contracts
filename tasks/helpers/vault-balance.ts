import { Voyage, WETH9 } from '@contracts';
import { formatWad } from '@helpers/math';
import { getWETH9 } from '@helpers/task-helpers/addresses';
import { task } from 'hardhat/config';

task('dev:vault-balance', 'Prints vault balance in ETH/WETH')
  .addOptionalParam('vault', 'The vault to check.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const weth9Address = await getWETH9();
    const weth9 = await ethers.getContractAt<WETH9>('WETH9', weth9Address);
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const { owner } = await getNamedAccounts();
    const defaultVault = await voyage.getVault(owner);
    const { vault = defaultVault } = params;
    const ETHBalance = await ethers.provider.getBalance(vault);
    const WETHBalance = await weth9.balanceOf(vault);
    console.log(`Balance of ${vault} in ETH: ${formatWad(ETHBalance)}`);
    console.log(`balance of ${vault} in WETH: ${formatWad(WETHBalance)}`);
  });

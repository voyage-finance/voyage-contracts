import { Voyage, WETH9 } from '@contracts';
import { formatWad } from '@helpers/math';
import { task } from 'hardhat/config';

task('dev:vault-balance', 'Prints vault balance in ETH/WETH')
  .addOptionalParam('vault', 'The vault to check.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const WETH9 = await ethers.getContract<WETH9>('WETH9');
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const { owner } = await getNamedAccounts();
    const defaultVault = await voyage.getVault(owner);
    const { vault = defaultVault } = params;
    const ETHBalance = await ethers.provider.getBalance(vault);
    const WETHBalance = await WETH9.balanceOf(vault);
    console.log(`Balance of ${vault} in ETH: ${formatWad(ETHBalance)}`);
    console.log(`balance of ${vault} in WETH: ${formatWad(WETHBalance)}`);
  });

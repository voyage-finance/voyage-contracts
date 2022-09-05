import { WETH9 } from '@contracts';
import { BigNumber } from 'ethers';
import { HRE } from './set-hre';

/**
 * Funds a vault
 * @param vault - address of the vault to fund
 * @param amount - amount to fund
 */
export async function fund(vault: string, amount: BigNumber, sender: string) {
  const { ethers } = HRE;
  const signer = await ethers.getSigner(sender);
  const weth9 = await ethers.getContract<WETH9>('WETH9', signer);
  const balance = await weth9.balanceOf(signer.address);
  console.log('balance: ', balance.toString());
  if (balance.lt(amount)) {
    await weth9.deposit({ value: amount.sub(balance) });
  }
  await signer.sendTransaction({ to: vault, value: amount });
  const tx = await weth9.transferFrom(sender, vault, amount);
  const receipt = await tx.wait();
  return receipt;
}

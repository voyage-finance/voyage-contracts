import { WETH9 } from '@contracts';
import { BigNumber } from 'ethers';
import { getWETH9 } from './addresses';
import { HRE } from './hre';

/**
 * Funds a vault
 * @param vault - address of the vault to fund
 * @param amount - amount to fund
 */
export async function fund(
  vault: string,
  amount: BigNumber,
  sender: string,
  sendETH: boolean = false
) {
  const { ethers } = HRE;
  const signer = await ethers.getSigner(sender);
  const weth9Address = await getWETH9();
  const weth9 = await ethers.getContractAt<WETH9>(
    'WETH9',
    weth9Address,
    signer
  );
  const balance = await weth9.balanceOf(signer.address);
  console.log('Vault WETH balance: ', balance.toString());
  if (balance.lt(amount)) {
    await weth9.deposit({ value: amount.sub(balance) });
  }
  if (sendETH) {
    const sendEthTx = await signer.sendTransaction({
      to: vault,
      value: amount,
    });
    await sendEthTx.wait();
  }
  const tx = await weth9.transferFrom(sender, vault, amount);
  const receipt = await tx.wait();
  return receipt;
}

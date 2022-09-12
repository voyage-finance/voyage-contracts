import { MAX_UINT_256 } from '@helpers/math';
import { BigNumber } from 'ethers';
import { Voyage, WETH9 } from '@contracts';
import { Tranche } from '../types';
import { HRE } from './hre';

export async function deposit(
  collection: string,
  tranche: Tranche,
  amount: BigNumber,
  signer: string
) {
  const { ethers } = HRE;
  const voyage = await ethers.getContract<Voyage>('Voyage', signer);
  const weth9 = await ethers.getContract<WETH9>('WETH9', signer);
  const balance = await weth9.balanceOf(signer);
  console.log('balance: ', balance.toString());
  if (balance.lt(amount)) {
    await weth9.deposit({ value: amount.sub(balance) });
  }
  const allowance = await weth9.allowance(signer, voyage.address);
  if (allowance.lt(MAX_UINT_256)) {
    await weth9.approve(voyage.address, MAX_UINT_256);
  }
  const tx = await voyage.deposit(collection, tranche, amount);
  await tx.wait();
}

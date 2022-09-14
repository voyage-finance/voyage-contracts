import { MAX_UINT_256 } from '@helpers/math';
import { BigNumber } from 'ethers';
import { Voyage, WETH9 } from '@contracts';
import { Tranche } from '../types';
import { HRE } from './hre';
import { getWETH9 } from './addresses';

export async function deposit(
  collection: string,
  tranche: Tranche,
  amount: BigNumber,
  signer: string
) {
  const { ethers } = HRE;
  const voyage = await ethers.getContract<Voyage>('Voyage', signer);
  const weth9Address = await getWETH9();
  const weth9 = await ethers.getContractAt<WETH9>(
    'WETH9',
    weth9Address,
    signer
  );
  const balance = await weth9.balanceOf(signer);
  console.log('Pre-deposit WETH9 balance: ', ethers.utils.formatEther(balance));
  if (balance.lt(amount)) {
    const tx = await weth9.deposit({ value: amount.sub(balance) });
    await tx.wait();
  }
  const allowance = await weth9.allowance(signer, voyage.address);
  if (allowance.lt(MAX_UINT_256)) {
    const tx = await weth9.approve(voyage.address, MAX_UINT_256);
    await tx.wait();
  }
  const tx = await voyage.deposit(collection, tranche, amount);
  await tx.wait();
}

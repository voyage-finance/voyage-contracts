import { ContractTransaction, Transaction } from 'ethers';
import hre, { ethers } from 'hardhat';
import { MAX_UINT_256 } from './math';

export const JR_TOKEN_NAME = 'JuniorDepositToken';
export const SR_TOKEN_NAME = 'SeniorDepositToken';

export async function grantAllowance() {
  const { owner } = await hre.getNamedAccounts();
  const tus = await ethers.getContract('Tus', owner);
  const lm = await ethers.getContract('LiquidityManager', owner);

  const currentAllowance = await tus.allowance(owner, lm.address);
  const max = ethers.BigNumber.from(MAX_UINT_256);

  // grant max uint256, avoid overflow
  await tus.increaseAllowance(lm.address, max.sub(currentAllowance));
}

export async function confirm(tx: ContractTransaction) {
  return tx.wait();
}

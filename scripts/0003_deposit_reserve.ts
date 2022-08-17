import { Voyage } from '@contracts';
import { ethers } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const weth = await ethers.getContract('WETH9');
  const crab = await ethers.getContract('Crab');
  // max approve voyage, for deposits
  let tx = await weth.deposit({ value: ethers.utils.parseEther('1') });
  await tx.wait();
  tx = await weth.approve(voyage.address, MAX_UINT_256);
  await tx.wait();
  const depositAmount = ethers.BigNumber.from(500);

  tx = await voyage.deposit(crab.address, 1, depositAmount);
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

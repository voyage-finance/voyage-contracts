import { Voyage } from '@contracts';
import { ethers } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const weth = await ethers.getContract('WETH9');
  const crab = await ethers.getContract('Crab');
  const collection = '0x6C5AE80Bcf0Ec85002FE8eb3Ce267232614127C0';
  // max approve voyage, for deposits
  let tx = await weth.deposit({ value: ethers.utils.parseEther('10000000') });
  await tx.wait();
  tx = await weth.approve(voyage.address, MAX_UINT_256);
  await tx.wait();
  const depositAmount = ethers.utils.parseEther('10000');

  tx = await voyage.deposit(collection, 0, depositAmount);
  await tx.wait();
  tx = await voyage.deposit(collection, 1, depositAmount);
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

import { ethers } from 'hardhat';
import { Voyage } from '../typechain/Voyage';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const tus = await ethers.getContract('Tus');
  const tx = await voyage.setMarginParams(
    tus.address,
    0,
    68719476735, // max margin
    0.1 * 1e4 // 0.1 in BPs
  );
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

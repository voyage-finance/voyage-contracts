import { ethers } from 'hardhat';
import { PriceOracle } from '@contracts';
import { toWad } from '../helpers/math';

async function main() {
  const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
  const collection = '0x6C5AE80Bcf0Ec85002FE8eb3Ce267232614127C0';
  const tx = await priceOracle.updateTwap(collection, toWad(0.0001));
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

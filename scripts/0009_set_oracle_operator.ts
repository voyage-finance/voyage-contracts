import { PriceOracle } from '@contracts';
import { ethers } from 'hardhat';
import { confirm } from '../helpers/contract';

async function main() {
  const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
  await priceOracle
    .setOperator('0xbeb4b7a96dd4fc94767e6cc9e5ce881bc0db2b5d', true)
    .then(confirm);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

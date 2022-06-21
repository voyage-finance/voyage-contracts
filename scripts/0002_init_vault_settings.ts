import { ContractTransaction } from 'ethers';
import { ethers } from 'hardhat';
import { Voyager } from '../typechain/Voyager';

async function main() {
  const voyager = await ethers.getContract<Voyager>('Voyager');
  const tus = await ethers.getContract('Tus');
  let tx: ContractTransaction = await voyager.setMarginRequirement(
    tus.address,
    '100000000000000000000000000'
  );
  await tx.wait();
  tx = await voyager.setMaxMargin(tus.address, '100000000000000000000000000');
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

import { ContractTransaction } from 'ethers';
import { ethers } from 'hardhat';
import { Voyage } from '../typechain/Voyage';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const tus = await ethers.getContract('Tus');
  let tx: ContractTransaction = await voyage.setMarginRequirement(
    tus.address,
    '100000000000000000000000000'
  );
  await tx.wait();
  tx = await voyage.setMaxMargin(tus.address, '100000000000000000000000000');
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

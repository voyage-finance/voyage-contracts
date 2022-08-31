import { ethers } from 'hardhat';
import { Voyage } from '@contracts';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  await voyage.updateMarketPlaceData(
    '0x1AA777972073Ff66DCFDeD85749bDD555C0665dA',
    '0x84b46875338c38E99a29D66Ab59B49778A7B4793'
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

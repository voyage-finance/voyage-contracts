import { ethers } from 'hardhat';
import { Voyage } from '@contracts';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  await voyage.updateMarketPlaceData(
    '0x1AA777972073Ff66DCFDeD85749bDD555C0665dA',
    '0xB1559cf7fF5Da13589DBB041Dcf9Be9948D6d064'
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

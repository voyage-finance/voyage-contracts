import { Voyage } from '@contracts';
import { MAX_UINT_256, toEthersBN, WAD } from '../helpers/math';
import { ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const tus = await ethers.getContract('Tus');
  // max approve voyage, for deposits
  let tx = await tus.approve(voyage.address, MAX_UINT_256);
  await tx.wait();
  const depositAmount = ethers.BigNumber.from(500_000).mul(toEthersBN(WAD));

  tx = await voyage.deposit(tus.address, '1', depositAmount, owner);
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

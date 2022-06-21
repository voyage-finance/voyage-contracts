import { Voyager } from '@contracts';
import { MAX_UINT_256, toEthersBN, WAD } from '../helpers/math';
import { ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract<Voyager>('Voyager');
  const tus = await ethers.getContract('Tus');
  // max approve voyager, for deposits
  let tx = await tus.approve(voyager.address, MAX_UINT_256);
  await tx.wait();
  const depositAmount = ethers.BigNumber.from(500_000).mul(toEthersBN(WAD));

  tx = await voyager.deposit(tus.address, '1', depositAmount, owner);
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

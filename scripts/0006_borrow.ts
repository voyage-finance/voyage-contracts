import { Voyage } from '@contracts';
import { deployments, ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const vaultAddress = await voyage.getVault(owner);
  const tus = await deployments.get('Tus');

  let tx = await voyage.borrow(
    tus.address,
    '10000000000000000000',
    vaultAddress
  );
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

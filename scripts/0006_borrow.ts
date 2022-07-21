import { Voyage } from '@contracts';
import { deployments, ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const vaultAddress = await voyage.getVault(owner);
  console.log('vault address: ', vaultAddress);
  const tus = await deployments.get('Tus');
  const { execute } = deployments;
  // let tx = await voyage.borrow(
  //   tus.address,
  //   '100000000000000000000',
  //   vaultAddress
  // );
  await execute(
    'Voyage',
    {
      from: owner,
      log: true,
      gasLimit: 12450000,
    },
    'borrow',
    tus.address,
    '100000000000000000000',
    vaultAddress
  );
  // await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

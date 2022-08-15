import { Vault, Voyage } from '@contracts';
import { MAX_UINT_256 } from '../helpers/math';
import { ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const crab = await ethers.getContract('Crab');
  const vaultAddress = await voyage.getVault(owner);
  if (vaultAddress === ethers.constants.AddressZero) {
    throw new Error('Owner has no vault');
  }
  const vault = (await ethers.getContractFactory('Vault')).attach(vaultAddress);

  const tus = await ethers.getContract('Tus', owner);
  // max approve vault
  let tx = await tus.approve(vault.address, MAX_UINT_256);
  await tx.wait();

  tx = await voyage.depositMargin(
    vault.address,
    crab.address,
    '100000000000000000000'
  );
  await tx.wait();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

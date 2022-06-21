import { Vault, Voyager } from '@contracts';
import { MAX_UINT_256 } from '../helpers/math';
import { ethers, getNamedAccounts } from 'hardhat';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract<Voyager>('Voyager');
  const vaultAddress = await voyager.getVault(owner);
  if (vaultAddress === ethers.constants.AddressZero) {
    throw new Error('Owner has no vault');
  }
  const vault = await ethers.getContractAt<Vault>('Vault', vaultAddress);
  const escrowAddress = await vault.getMarginEscrowAddress();
  console.log('vault escrow address: ', escrowAddress);

  // max approve sd
  const tus = await ethers.getContract('Tus', owner);
  let tx = await tus.approve(escrowAddress, MAX_UINT_256);
  await tx.wait();

  tx = await voyager.depositMargin(
    owner,
    owner,
    tus.address,
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

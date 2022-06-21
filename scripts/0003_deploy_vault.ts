import { ethers, getNamedAccounts } from 'hardhat';
import { Voyager } from '../typechain/Voyager';

async function main() {
  const { owner } = await getNamedAccounts();
  const tus = await ethers.getContract('Tus');
  const voyager = await ethers.getContract<Voyager>('Voyager', owner);
  const vaultAddress = await voyager.getVault(owner);
  ethers.BigNumber;
  if (ethers.BigNumber.from(vaultAddress).isZero()) {
    const tx = await voyager.createVault(owner, tus.address);
    await tx.wait();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

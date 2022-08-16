import { ethers, getNamedAccounts, tenderly } from 'hardhat';
import { Vault } from '../typechain/Vault';
import { Voyage } from '../typechain/Voyage';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage', owner);
  let vaultAddress = await voyage.getVault(owner);
  console.log('vault address: ', vaultAddress);
  if (ethers.BigNumber.from(vaultAddress).isZero()) {
    const salt = ethers.utils.randomBytes(20);
    const tx = await voyage.createVault(owner, salt);
    await tx.wait();
    console.log('createVault tx hash: ', tx.hash);
    vaultAddress = await voyage.getVault(owner);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

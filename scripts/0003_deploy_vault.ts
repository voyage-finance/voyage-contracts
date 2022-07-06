import { ethers, getNamedAccounts } from 'hardhat';
import { Vault } from '../typechain/Vault';
import { Voyage } from '../typechain/Voyage';

async function main() {
  const { owner } = await getNamedAccounts();
  const tus = await ethers.getContract('Tus');
  const voyage = await ethers.getContract<Voyage>('Voyage', owner);
  let vaultAddress = await voyage.getVault(owner);
  if (ethers.BigNumber.from(vaultAddress).isZero()) {
    const tx = await voyage.createVault(owner);
    await tx.wait();
    vaultAddress = await voyage.getVault(owner);
  }
  const vault = await ethers.getContractAt<Vault>('Vault', vaultAddress);
  const marginEscrow = await vault.marginEscrow(tus.address);
  if (ethers.BigNumber.from(marginEscrow).isZero()) {
    const initTx = await voyage.initAsset(vaultAddress, tus.address);
    await initTx.wait();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

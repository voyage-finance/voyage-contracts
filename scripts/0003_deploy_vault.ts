import { ethers, getNamedAccounts } from 'hardhat';
import { Vault } from '../typechain/Vault';
import { Voyager } from '../typechain/Voyager';

async function main() {
  const { owner } = await getNamedAccounts();
  const tus = await ethers.getContract('Tus');
  const voyager = await ethers.getContract<Voyager>('Voyager', owner);
  let vaultAddress = await voyager.getVault(owner);
  if (ethers.BigNumber.from(vaultAddress).isZero()) {
    const tx = await voyager.createVault(owner);
    await tx.wait();
    vaultAddress = await voyager.getVault(owner);
  }
  const vault = await ethers.getContractAt<Vault>('Vault', vaultAddress);
  const marginEscrow = await vault.marginEscrow(tus.address);
  if (ethers.BigNumber.from(marginEscrow).isZero()) {
    const initTx = await voyager.initAsset(vaultAddress, tus.address);
    await initTx.wait();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

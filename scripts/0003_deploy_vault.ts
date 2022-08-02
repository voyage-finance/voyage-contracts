import { ethers, getNamedAccounts, tenderly } from 'hardhat';
import { Vault } from '../typechain/Vault';
import { Voyage } from '../typechain/Voyage';

async function main() {
  const { owner } = await getNamedAccounts();
  const tus = await ethers.getContract('Tus');
  const crab = await ethers.getContract('Crab');
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
  const vault = await ethers.getContractAt<Vault>(
    'hardhat-diamond-abi/HardhatDiamondABI.sol:Vault',
    vaultAddress
  );
  const marginEscrow = await vault.marginEscrow(tus.address);
  console.log('margin escrow: ', marginEscrow);
  if (ethers.BigNumber.from(marginEscrow).isZero()) {
    const initTx = await voyage.initCreditLine(
      vaultAddress,
      tus.address,
      crab.address
    );
    await initTx.wait();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

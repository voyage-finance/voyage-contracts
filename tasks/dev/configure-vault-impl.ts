import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task(
  'dev:configure-vault-impl',
  'Set the vault implementation to the current deployed one.'
)
  .addOptionalParam(
    'sender',
    'The sender of the transaction. Defaults to owner.'
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { sender } = params;
    const { owner } = await hre.getNamedAccounts();
    const signer = await ethers.getSigner(sender ?? owner);
    const voyage = await ethers.getContract<Voyage>('Voyage', signer);
    const vault = await ethers.getContract('Vault');
    const tx = await voyage.setVaultImpl(vault.address);
    const receipt = await tx.wait();
    console.log(`Set vault implementation to ${vault.address}`);
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

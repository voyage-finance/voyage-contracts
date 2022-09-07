import { Vault } from '@contracts';
import { task } from 'hardhat/config';

task(
  'dev:vault-approve-weth',
  'Approves voyage to manage WETH on the vault behalf'
)
  .addParam('vault', 'The vault to call')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const { vault } = params;
    const { owner } = await getNamedAccounts();
    const vaultInstance = await ethers.getContractAt<Vault>(
      'Vault',
      vault,
      owner
    );
    const tx = await vaultInstance.approveVoyage();
    const receipt = await tx.wait();
    console.log(`Max approved Voyage to manage WETH for ${vault}`);
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

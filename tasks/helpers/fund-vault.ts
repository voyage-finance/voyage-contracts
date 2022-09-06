import { Voyage } from '@contracts';
import { fund } from '@helpers/task-helpers/vault';
import { task, types } from 'hardhat/config';

task('dev:fund-vault', 'Fund a Vault with ETH')
  .addOptionalParam(
    'vault',
    'Address of the vault to fund. Defaults to owner vault.'
  )
  .addOptionalParam('sender', 'Address to send ETH with. Defaults to owner.')
  .addOptionalParam('amount', 'Amount to fund in ETH', '10000', types.string)
  .addFlag('sendEth', 'Whether to also fund ETH in addition to WETH')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const voyage = await hre.ethers.getContract<Voyage>('Voyage');
    const { owner } = await hre.getNamedAccounts();
    const ownerVault = await voyage.getVault(owner);
    const { vault = ownerVault, sender = owner, amount, sendEth } = params;
    const receipt = await fund(
      vault,
      hre.ethers.utils.parseEther(amount),
      sender,
      sendEth
    );
    console.log(`Funded vault at ${vault} with ${amount} ETH from ${sender}\n`);
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

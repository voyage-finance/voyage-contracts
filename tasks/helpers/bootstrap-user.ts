import { Voyage, WETH9 } from '@contracts';
import { task, types } from 'hardhat/config';

task(
  'dev:bootstrap-user',
  'Funds the user account, creates a vault, and funds the vault'
)
  .addParam('receiver', 'Receiving user address')
  .addOptionalParam('sender', 'The account to user to send the ETH')
  .addOptionalParam('user', 'User target balance in ETH', '1', types.string)
  .addOptionalParam('vault', 'Target vault balance', '1', types.string)
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const { receiver, sender = owner, user, vault } = params;
    const userETHBal = await ethers.provider.getBalance(receiver);
    const targetBalance = ethers.utils.parseEther(user);
    if (userETHBal.lt(targetBalance)) {
      const ethDeposit = targetBalance.sub(userETHBal);
      const signer = await ethers.getSigner(sender);
      const tx = await signer.sendTransaction({
        from: sender,
        to: receiver,
        value: ethDeposit,
      });
      await tx.wait();
    }

    console.log(`Creating vault for user ${receiver}\n`);
    await hre.run('dev:create-vault', { user: receiver });

    const voyage = await ethers.getContract<Voyage>('Voyage');
    const vaultAddress = await voyage.getVault(receiver);
    console.log(`Funding the vault ${vaultAddress} with ${vault} ETH\n`);
    await hre.run('dev:fund-vault', {
      amount: vault,
      sender,
      vault: vaultAddress,
      sendeth: true,
    });
  });

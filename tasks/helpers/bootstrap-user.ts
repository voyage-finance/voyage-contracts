import { Voyage, WETH9 } from '@contracts';
import { getWETH9 } from '@helpers/task-helpers/addresses';
import { task, types } from 'hardhat/config';

task(
  'dev:bootstrap-user',
  'Funds the user account, creates a vault, and funds the vault'
)
  .addParam('receiver', 'Receiving user address')
  .addOptionalParam('sender', 'The account to user to send the ETH')
  .addOptionalParam('eth', 'User target balance in ETH', '1', types.string)
  .addOptionalParam('weth', 'User target balance in WETH', '1', types.string)
  .addOptionalParam('vault', 'Target vault balance in WETH', '1', types.string)
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const { receiver, sender = owner, eth, weth, vault } = params;
    const signer = await ethers.getSigner(sender);
    const userETHBalance = await ethers.provider.getBalance(receiver);
    const targetETHBalance = ethers.utils.parseEther(eth);
    if (userETHBalance.lt(targetETHBalance)) {
      const ethDeposit = targetETHBalance.sub(userETHBalance);
      const tx = await signer.sendTransaction({
        from: sender,
        to: receiver,
        value: ethDeposit,
      });
      await tx.wait();
      console.log(
        `Sent ${ethers.utils.formatEther(ethDeposit)} ETH to ${receiver}.\n`
      );
    }

    const weth9Address = await getWETH9();
    const weth9 = await ethers.getContractAt<WETH9>(
      'WETH9',
      weth9Address,
      signer
    );
    const userWETHBalance = await weth9.balanceOf(receiver);
    const targetWETHBalance = ethers.utils.parseEther(weth);
    if (userWETHBalance.lt(targetWETHBalance)) {
      const wethDeposit = targetWETHBalance.sub(userWETHBalance);
      const tx = await signer.sendTransaction({
        from: sender,
        to: receiver,
        value: wethDeposit,
      });
      await tx.wait();
      await hre.run('dev:deposit-weth', {
        amount: ethers.utils.formatEther(wethDeposit),
        sender: receiver,
      });
    }
    console.log(`Creating vault for user ${receiver}\n`);
    await hre.run('dev:create-vault', { user: receiver });

    const voyage = await ethers.getContract<Voyage>('Voyage');
    const vaultAddress = await voyage.getVault(receiver);
    console.log(
      `Funding the vault ${vaultAddress} with ${vault} ETH and WETH.\n`
    );
    await hre.run('dev:fund-vault', {
      amount: vault,
      sender,
      vault: vaultAddress,
      sendeth: true,
    });
  });

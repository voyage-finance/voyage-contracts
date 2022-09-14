import { WETH9 } from '@contracts';
import { getWETH9 } from '@helpers/task-helpers/addresses';
import { task } from 'hardhat/config';

task('dev:unwrap-weth', 'Unwraps WETH for the given account')
  .addOptionalParam('weth', 'The address of the WETH contract')
  .addOptionalParam('address', 'The address to unwrap for.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const { owner } = await getNamedAccounts();
    const defaultWeth = await getWETH9();
    const { weth = defaultWeth, address = owner } = params;
    const signer = await ethers.getSigner(address);
    const contract = await ethers.getContractAt<WETH9>('WETH9', weth, signer);
    const balance = await contract.balanceOf(signer.address);
    const tx = await contract.withdraw(balance);
    const receipt = await tx.wait();
    console.log(
      `${signer.address} unwrapped ${ethers.utils.formatEther(balance)}.`
    );
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

import { Voyage, WETH9 } from '@contracts';
import { MAX_UINT_256 } from '@helpers/math';
import { task } from 'hardhat/config';

task('dev:approve-weth', 'approves the given spender for the given account')
  .addOptionalParam('approver', 'The account giving approval.')
  .addOptionalParam('spender', 'The spender to approve.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const { owner } = await getNamedAccounts();
    const { approver = owner, spender = voyage.address } = params;
    const signer = await ethers.getSigner(approver);
    const weth9 = await ethers.getContract<WETH9>('WETH9', signer);
    const tx = await weth9.approve(spender, MAX_UINT_256);
    const receipt = await tx.wait();
    console.log(`${approver} approved ${spender}.`);
    console.log(`Transaction hash: ${receipt.transactionHash}`);
  });

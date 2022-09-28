import { Voyage, WETH9 } from '@contracts';
import { MAX_UINT_256 } from '@helpers/math';
import { getWETH9 } from '@helpers/task-helpers/addresses';
import { task } from 'hardhat/config';

task(
  'dev:approve-marketplace',
  'Approves or revokes approval for marketplace to spend WETH on behalf of the given vault'
)
  .addParam('owner', 'Vault owner address.')
  .addParam('marketplace', 'The marketplace to approve.')
  .addFlag('revoke', 'Revokes approval if set.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage', params.owner);
    const vault = await voyage.getVault(params.owner);
    const tx = await voyage.approveMarketplace(
      vault,
      params.marketplace,
      params.revoke
    );
    const receipt = await tx.wait();
    console.log(
      'Approval tx successfully sent. Tx hash: ',
      receipt.transactionHash
    );
    const weth9 = await ethers.getContractAt<WETH9>('WETH9', await getWETH9());
    const allowance = await weth9.allowance(vault, params.marketplace);
    console.log(
      `Current allowance of ${
        params.marketplace
      } to spend ${vault} WETH is ${ethers.utils.formatEther(allowance)} WETH`
    );
  });

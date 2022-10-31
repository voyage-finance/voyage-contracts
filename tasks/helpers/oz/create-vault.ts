import { task } from 'hardhat/config';
import { Voyage } from '@contracts';
import { REFUND_GAS_PRICE, REFUND_GAS_UNIT } from '@helpers/constants';
import { fund } from '@helpers/task-helpers/vault';
import {
  DefenderRelayProvider,
  DefenderRelaySigner,
} from 'defender-relay-client/lib/ethers';

task('dev:oz-create-vault', 'Creates a vault via OZ relay.')
  .addOptionalParam('user', 'Address of the vault owner.')
  .addOptionalParam('salt', 'Salt to use for vault creation.')
  .addOptionalParam('gaslimit', 'Gas limit')
  .addOptionalParam('gasprice', 'Gas price')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const credentials = {
      apiKey: process.env.OZ_API_KEY as string,
      apiSecret: process.env.OZ_API_SECRET as string,
    };
    if (!credentials.apiKey || !credentials.apiSecret) {
      throw new Error('No OZ credentials found.');
    }
    const provider = new DefenderRelayProvider(credentials);
    const signer = new DefenderRelaySigner(credentials, provider, {
      speed: 'average',
      validForSeconds: 180,
    });
    const { ethers } = hre;
    // @ts-ignore
    const voyage = await ethers.getContract<Voyage>('Voyage', signer);
    const { user, salt, gaslimit, gasprice } = params;
    let vaultAddress = await voyage.getVault(user);
    if (vaultAddress === ethers.constants.AddressZero) {
      console.log(
        `${user} does not have a vault. Creating vault with salt ${ethers.utils.hexlify(
          salt
        )}`
      );
      const tx = await voyage.createVault(
        user,
        salt,
        gaslimit,
        ethers.BigNumber.from(gasprice),
        { gasLimit: 600000 }
      );
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed;
      console.log(`createVault used ${gasUsed.toString()} gas`);
      console.log(
        `The cost is ${ethers.utils.formatEther(
          gasUsed.mul(ethers.utils.parseUnits('5', 'gwei'))
        )} ETH`
      );
      vaultAddress = await voyage.getVault(user);
    }
    console.log(`Vault address for ${user} is ${vaultAddress}`);
  });

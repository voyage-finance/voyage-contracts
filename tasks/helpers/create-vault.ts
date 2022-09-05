import { task } from 'hardhat/config';
import { Voyage } from '@contracts';

task(
  'dev:create-vault',
  'Creates a vault, or prints the address if one already exists.'
)
  .addOptionalParam('user', 'Address of the vault owner.')
  .addOptionalParam('salt', 'Salt to use for vault creation.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers, getNamedAccounts } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const { owner } = await getNamedAccounts();
    const { user = owner, salt = ethers.utils.randomBytes(20) } = params;
    let vaultAddress = await voyage.getVault(user);
    if (vaultAddress === ethers.constants.AddressZero) {
      console.log(
        `${user} does not have a vault. Creating vault with salt ${ethers.utils.hexlify(
          salt
        )}`
      );
      const tx = await voyage.createVault(user, salt);
      await tx.wait();
      vaultAddress = await voyage.getVault(user);
    }
    console.log(`Vault address for ${user} is ${vaultAddress}`);
  });

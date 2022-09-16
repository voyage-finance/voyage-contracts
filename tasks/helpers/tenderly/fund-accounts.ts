import { task, types } from 'hardhat/config';

task('tenderly:fund-accounts', 'Funds the first 10 mnemonic accounts.')
  .addOptionalParam(
    'amount',
    'The amount to fund. Defaults to 10000000 ETH.',
    '1000000',
    types.string
  )
  .setAction(async (_, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const wallets = [];
    const signers = await hre.ethers.getSigners();
    for (const signer of signers) {
      const address = await signer.getAddress();
      wallets.push(address);
    }
    console.log('funding wallets: \n', wallets);
    const result = await ethers.provider.send('tenderly_setBalance', [
      wallets,
      //amount in wei will be set for all wallets
      ethers.utils.hexValue(
        ethers.utils.parseUnits('10000000', 'ether').toHexString()
      ),
    ]);
    console.log('result: ', result);
  });

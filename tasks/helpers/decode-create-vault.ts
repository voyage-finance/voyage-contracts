import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task('dev:decode-create-vault', 'Decodes the given create vault calldata')
  .addParam('calldata', 'The calldata to decode')
  .setAction(async (params, hre) => {
    const { ethers } = hre;
    await hre.run('set-hre');
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const buyNow = voyage.interface.decodeFunctionData(
      'createVault',
      params.calldata
    );
    console.log('decoded calldata: \n\n');
    console.log({
      ...buyNow,
      _gasUnits: buyNow._gasUnits.toString(),
      _gasPrice: buyNow._gasPrice.toString(),
    });
  });

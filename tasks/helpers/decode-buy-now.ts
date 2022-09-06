import { Voyage } from '@contracts';
import { task } from 'hardhat/config';

task('dev:decode-buynow', 'Decodes the given buyNow calldata')
  .addParam('calldata', 'The calldata to decode')
  .setAction(async (params, hre) => {
    const { ethers } = hre;
    await hre.run('set-hre');
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const buyNow = voyage.interface.decodeFunctionData(
      'buyNow',
      params.calldata
    );
    console.log('decoded calldata: \n\n');
    console.log(buyNow);
  });

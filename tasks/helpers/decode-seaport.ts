import { Voyage } from '@contracts';
import { SeaportABI } from '@opensea/seaport-js/lib/abi/Seaport';
import { task } from 'hardhat/config';

task('dev:decode-seaport', 'Decodes the given Seaport calldata')
  .addParam('calldata', 'The calldata to decode')
  .setAction(async (params, hre) => {
    const { ethers } = hre;
    await hre.run('set-hre');
    const seaport = new ethers.Contract(
      ethers.constants.AddressZero,
      SeaportABI,
      ethers.provider
    );
    const decoded = seaport.interface.decodeFunctionData(
      'fulfillBasicOrder',
      params.calldata
    );
    console.log('decoded calldata:\n\n');
    console.log(decoded);
  });

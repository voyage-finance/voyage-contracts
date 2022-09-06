import { Voyage } from '@contracts';
import { LooksRareExchangeAbi } from '@looksrare/sdk';
import { task } from 'hardhat/config';

task('dev:decode-looks', 'Decodes the given LooksRare calldata')
  .addParam('calldata', 'The calldata to decode')
  .setAction(async (params, hre) => {
    const { ethers } = hre;
    await hre.run('set-hre');
    const looks = new ethers.Contract(
      ethers.constants.AddressZero,
      LooksRareExchangeAbi,
      ethers.provider
    );
    const decoded = looks.interface.decodeFunctionData(
      'matchAskWithTakerBidUsingETHAndWETH',
      params.calldata
    );
    console.log('decoded calldata:\n\n');
    console.log(decoded);
  });

import { task } from 'hardhat/config';
import { LooksRareExchangeAbi } from '@looksrare/sdk';

task('dev:decode-looks-error', 'Decode Seaport error')
  .addParam('sighash', 'Signature of the error')
  .setAction(async (params, hre) => {
    const { sighash } = params;
    const looks = new hre.ethers.Contract(
      hre.ethers.constants.AddressZero,
      LooksRareExchangeAbi
    );
    const fragment = looks.interface.getError(sighash);
    console.log(fragment.name);
  });

import { task } from 'hardhat/config';
import { SeaportABI } from '@opensea/seaport-js/lib/abi/Seaport';

task('dev:decode-seaport-error', 'Decode Seaport error')
  .addParam('sighash', 'Signature of the error')
  .setAction(async (params, hre) => {
    const { sighash } = params;
    const seaport = new hre.ethers.Contract(
      hre.ethers.constants.AddressZero,
      SeaportABI
    );
    const fragment = seaport.interface.getError(sighash);
    console.log(fragment.name);
  });

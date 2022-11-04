import { task } from 'hardhat/config';

task('dev:decode-voyage-error', 'Decode Voyage error')
  .addParam('sighash', 'Signature of the error')
  .setAction(async (params, hre) => {
    const { sighash } = params;
    const voyage = await hre.ethers.getContract('Voyage');
    const fragment = voyage.interface.getError(sighash);
    console.log(fragment.name);
  });

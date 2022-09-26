import { PriceOracle } from '@contracts';
import { task } from 'hardhat/config';

// OZ Relayer addresses:
// Mainnet: 0x989d103d87dc8ee0fd06212bfd0bd6c08c661ed4
// Goerli: 0xbeb4b7a96dd4fc94767e6cc9e5ce881bc0db2b5d
task('dev:configure-twap-operator', 'Sets operator for twap')
  .addOptionalParam('operator', 'The operator address.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const {
      relayer = '0xbeb4b7a96dd4fc94767e6cc9e5ce881bc0db2b5d'
    } = params;
    const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
    const tx = await priceOracle.setOperator(relayer, true);
    await tx.wait();
    console.log('operator set: ', relayer);
  });

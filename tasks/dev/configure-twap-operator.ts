import { PriceOracle } from '@contracts';
import { TWAP_OPERATOR_ADDRESS } from '@helpers/constants';
import { task } from 'hardhat/config';

task('dev:configure-twap-operator', 'Sets operator for twap')
  .addOptionalParam('operator', 'The operator address.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const {
      relayer = TWAP_OPERATOR_ADDRESS
    } = params;
    const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
    const tx = await priceOracle.setOperator(relayer, true);
    await tx.wait();
    console.log('operator set: ', relayer);
  });

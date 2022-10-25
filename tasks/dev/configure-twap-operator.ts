import { PriceOracle } from '@contracts';
import { task } from 'hardhat/config';

task('dev:configure-twap-operator', 'Sets operator for twap')
  .addParam('operator', 'The operator address.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { operator } = params;
    const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
    const tx = await priceOracle.setOperator(operator, true);
    await tx.wait();
    console.log('operator set: ', operator);
  });

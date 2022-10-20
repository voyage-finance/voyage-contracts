import { PriceOracle } from '@contracts';
import { task } from 'hardhat/config';

task('dev:update-twap', 'Update twap')
  .addParam('currency', 'The currency address.')
  .addParam('priceAverage', 'The average price.')
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { currency, priceAverage } = params;
    const priceOracle = await ethers.getContract<PriceOracle>('PriceOracle');
    const tx = await priceOracle.updateTwap(currency, priceAverage);
    await tx.wait();
  });

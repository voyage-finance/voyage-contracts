import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Price Oracle', function () {
  it('Constant price should return same vaule', async function () {
    const { tus, priceOracle } = await setupTestSuite();

    await priceOracle.updateCumulative(tus.address, '100');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '100');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '100');

    await priceOracle.updateAssetPrice(tus.address);

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '100');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '100');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '100');

    await priceOracle.updateAssetPrice(tus.address);

    const average0 = await priceOracle.getAssetPrice(tus.address);
    console.log(average0.toString());
  });

  it('Set price should return correct value', async function () {
    const { tus, priceOracle } = await setupTestSuite();

    await priceOracle.updateCumulative(tus.address, '100');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '150');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '200');

    await priceOracle.updateAssetPrice(tus.address);

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '250');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '200');

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);

    await priceOracle.updateCumulative(tus.address, '150');

    await priceOracle.updateAssetPrice(tus.address);

    const average0 = await priceOracle.getAssetPrice(tus.address);
    console.log(average0.toString());
  });
});

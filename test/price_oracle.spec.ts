import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Price Oracle', function () {
  it('Owner should able to update price', async function () {
    const { priceOracle, weth } = await setupTestSuite();
    await priceOracle.updateTwap(weth.address, '100');
    const price = await priceOracle.getTwap(weth.address);
    await expect(price[0].toString()).to.equal('100');
  });

  it('Valid operator should able to update price', async function () {
    const { priceOracle, weth, alice } = await setupTestSuite();
    await priceOracle.setOperator(alice, true);
    await priceOracle
      .connect(await ethers.getSigner(alice))
      .updateTwap(weth.address, '100');
    const price = await priceOracle.getTwap(weth.address);
    await expect(price[0].toString()).to.equal('100');
  });

  it('InValid operator should able to update price', async function () {
    const { priceOracle, weth, alice } = await setupTestSuite();
    await priceOracle.setOperator(alice, true);
    await priceOracle.setOperator(alice, false);
    await expect(
      priceOracle
        .connect(await ethers.getSigner(alice))
        .updateTwap(weth.address, '100')
    ).to.be.revertedWithCustomError(priceOracle, 'InvalidOperator');
  });
});

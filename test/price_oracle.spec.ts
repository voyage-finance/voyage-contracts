import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { decimals, formatBN } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
const { BigNumber } = ethers;

describe('Price Oracle', function () {
  it('Owner should able to update price', async function () {
    const { priceOracle, tus } = await setupTestSuite();
    await priceOracle.updateTwap(tus.address, '100');
    const price = await priceOracle.getTwap(tus.address);
    await expect(price[0].toString()).to.equal('100');
  });

  it('Valid operator should able to update price', async function () {
    const { priceOracle, tus, alice } = await setupTestSuite();
    await priceOracle.setOperator(alice, true);
    await priceOracle
      .connect(await ethers.getSigner(alice))
      .updateTwap(tus.address, '100');
    const price = await priceOracle.getTwap(tus.address);
    await expect(price[0].toString()).to.equal('100');
  });
});

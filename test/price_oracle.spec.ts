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

  // on demand twap part, V2
  it('should be able to set a valid twap tolerance', async () => {
    const { crab, voyage } = await setupTestSuite();
    // 3000 BPs, 30%
    const twapTolerance = ethers.BigNumber.from(3000);
    await expect(voyage.setTwapTolerance(crab.address, twapTolerance))
      .to.emit(voyage, 'TwapToleranceUpdated')
      .withArgs(crab.address, twapTolerance);
    const twap = await voyage.getTwapTolerance(crab.address);
    expect(twap).to.equal(twapTolerance);
  });

  it('set too big twap tolerance => revert', async () => {
    const { crab, voyage } = await setupTestSuite();
    // 65536 BPs, 655.36%. It is (type(uint16).max + 1)
    const invalidTwapTolerance = ethers.BigNumber.from(65536);
    await expect(
      voyage.setTwapTolerance(crab.address, invalidTwapTolerance)
    ).to.be.revertedWithCustomError(voyage, 'InvalidTwapTolerance');
  });

  it('should be able to set a valid oracle signer', async () => {
    const { voyage, bob } = await setupTestSuite();
    await voyage.setOracleSigner(bob);
    await expect(await voyage.getOracleSigner()).to.be.equal(bob);
  });
});

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { RAY, WAD } from '../helpers/constants';

describe('Reserve configuration', async () => {
  it('should be able to set a valid liquidation bonus', async () => {
    const { weth, voyage } = await setupTestSuite();
    // 10500 BPs, 105%
    const liquidationBonus = ethers.BigNumber.from(10500);
    await expect(voyage.setLiquidationBonus(weth.address, liquidationBonus))
      .to.emit(voyage, 'LiquidationConfigurationUpdated')
      .withArgs(weth.address, liquidationBonus);
    const conf = await voyage.getPoolConfiguration(weth.address);
    expect(conf.liquidationBonus).to.equal(liquidationBonus);
  });

  it('should revert with an error if the liquidation bonus is invalid', async () => {
    const { weth, voyage } = await setupTestSuite();
    // liquidation bonus is expressed in basis points; trying to express it as ray will cause revert
    const liquidationBonus = ethers.BigNumber.from(10500).mul(RAY);
    await expect(
      voyage.setLiquidationBonus(weth.address, liquidationBonus)
    ).to.be.revertedWithCustomError(voyage, 'InvalidLiquidationBonus');
  });

  it('should be able to set a valid income ratio', async () => {
    const { weth, voyage } = await setupTestSuite();
    // 0.5
    const incomeRatio = ethers.BigNumber.from(5000);
    await expect(voyage.setIncomeRatio(weth.address, incomeRatio))
      .to.emit(voyage, 'IncomeRatioUpdated')
      .withArgs(weth.address, incomeRatio);
  });

  it('should revert if income ratio exceeds 100%', async () => {
    const { weth, voyage } = await setupTestSuite();
    // 1.001
    const incomeRatio = ethers.BigNumber.from(10001);
    await expect(
      voyage.setIncomeRatio(weth.address, incomeRatio)
    ).to.be.revertedWithCustomError(voyage, 'InvalidIncomeRatio');
  });

  it('should set valid loan parameters', async () => {
    const { weth, voyage } = await setupTestSuite();
    const epoch = 30; // days
    const term = 90; // days
    const grace = 7; // days
    await expect(voyage.setLoanParams(weth.address, epoch, term, grace))
      .to.emit(voyage, 'LoanParametersUpdated')
      .withArgs(weth.address, epoch, term, grace);
  });

  it('should not allow invalid epoch', async () => {
    const { weth, voyage } = await setupTestSuite();
    const epoch = 256; // days
    const term = 365; // days
    const grace = 7; // days
    await expect(
      voyage.setLoanParams(weth.address, epoch, term, grace)
    ).to.be.revertedWithCustomError(voyage, 'InvalidLoanInterval');
  });

  it('should not allow epoch to exceed loan term', async () => {
    const { weth, voyage } = await setupTestSuite();
    const epoch = 90; // days
    const term = 30; // days
    const grace = 7; // days

    await expect(
      voyage.setLoanParams(weth.address, epoch, term, grace)
    ).to.be.revertedWithCustomError(voyage, 'IllegalLoanParameters');
  });

  it('should not allow loan term to be invalid', async () => {
    const { weth, voyage } = await setupTestSuite();
    const epoch = 90; // days
    const term = 65536; // days
    const grace = 7; // days

    await expect(
      voyage.setLoanParams(weth.address, epoch, term, grace)
    ).to.be.revertedWithCustomError(voyage, 'InvalidLoanTerm');
  });
});

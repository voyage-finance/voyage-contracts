import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

const RAY = ethers.BigNumber.from('1000000000000000000000000000');

describe('Liquidity Rate', function () {
  it('No borrow should return zero interest rate on deposit', async function () {
    const { crab, voyage } = await setupTestSuite();

    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';

    await voyage.deposit(crab.address, 0, juniorDepositAmount);
    await voyage.deposit(crab.address, 1, seniorDepositAmount);
    const poolData = await voyage.getPoolData(crab.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);

    expect(juniorLiquidityRate).to.equal(ethers.constants.Zero);
    expect(seniorLiquidityRate).to.equal(ethers.constants.Zero);
  });

  it('Junior deposit should return correct interest rate', async function () {
    const { owner, crab, voyage } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';
    await voyage.deposit(crab.address, 0, juniorDepositAmount);
    await voyage.deposit(crab.address, 1, seniorDepositAmount);
    await voyage.depositMargin(vault, crab.address, '100000000000000000000');

    await voyage.borrow(crab.address, '400000000000000000000', vault);
    const poolData = await voyage.getPoolData(crab.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);

    console.log('junior liquidity rate: ', juniorLiquidityRate);
    console.log('senior liquidity rate: ', seniorLiquidityRate);

    await voyage.deposit(crab.address, 0, juniorDepositAmount);
    const poolData1 = await voyage.getPoolData(crab.address);
    const juniorLiquidityRate1 = poolData1.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate1 = poolData1.seniorLiquidityRate.div(RAY);

    console.log('junior liquidity rate: ', juniorLiquidityRate1);
    console.log('senior liquidity rate: ', seniorLiquidityRate1);
  });

  it('Senior deposit should return correct interest rate', async function () {
    const { owner, crab, voyage } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const seniorDepositAmount = '50000000000000000000';
    const juniorDepositAmount = '10000000000000000000';

    await voyage.deposit(crab.address, 0, juniorDepositAmount);
    await voyage.deposit(crab.address, 1, seniorDepositAmount);
    await voyage.depositMargin(vault, crab.address, '100000000000000000000');

    await voyage.borrow(crab.address, '25000000000000000000', vault);
    const poolData = await voyage.getPoolData(crab.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);

    console.log('junior liquidity rate: ', juniorLiquidityRate);
    console.log('senior liquidity rate: ', seniorLiquidityRate);

    await voyage.deposit(crab.address, 1, seniorDepositAmount);
    const poolData1 = await voyage.getPoolData(crab.address);
    const juniorLiquidityRate1 = poolData1.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate1 = poolData1.seniorLiquidityRate.div(RAY);
    console.log('poolData1: ', poolData1);

    console.log('junior liquidity rate: ', juniorLiquidityRate1);
    console.log('senior liquidity rate: ', seniorLiquidityRate1);
  });

  it('Borrow should return correct interest rate', async function () {
    const { owner, tus, crab, seniorDepositToken, juniorDepositToken, voyage } =
      await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';

    await voyage.deposit(crab.address, 0, juniorDepositAmount);
    await voyage.deposit(crab.address, 1, seniorDepositAmount);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());

    await voyage.depositMargin(vault, crab.address, '100000000000000000000');
    await voyage.borrow(crab.address, '100000000000000000000', vault);

    const poolData = await voyage.getPoolData(crab.address);
    console.log('total liquidity: ', poolData.totalLiquidity.toString());

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);
    console.log('junior liquidity rate: ', juniorLiquidityRate.toString());
    console.log('senior liquidity rate: ', seniorLiquidityRate.toString());
  });
});

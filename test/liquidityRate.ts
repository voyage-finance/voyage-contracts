import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

const RAY = ethers.BigNumber.from('1000000000000000000000000000');

describe('Liquidity Rate', function () {
  it('No borrow should return zero interest rate on deposit', async function () {
    const { owner, tus, voyager } = await setupTestSuite();

    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    const poolData = await voyager.getPoolData(tus.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);

    expect(juniorLiquidityRate).to.equal(ethers.constants.Zero);
    expect(seniorLiquidityRate).to.equal(ethers.constants.Zero);
  });

  it('Junior deposit should return correct interest rate', async function () {
    const { owner, tus, vault, voyager } = await setupTestSuite();

    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';
    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    await voyager.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );

    await voyager.borrow(tus.address, '400000000000000000000', vault.address);
    const poolData = await voyager.getPoolData(tus.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);

    console.log('junior liquidity rate: ', juniorLiquidityRate);
    console.log('senior liquidity rate: ', seniorLiquidityRate);

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    const poolData1 = await voyager.getPoolData(tus.address);
    const juniorLiquidityRate1 = poolData1.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate1 = poolData1.seniorLiquidityRate.div(RAY);

    console.log('junior liquidity rate: ', juniorLiquidityRate1);
    console.log('senior liquidity rate: ', seniorLiquidityRate1);
  });

  it('Senior deposit should return correct interest rate', async function () {
    const { owner, tus, vault, voyager } = await setupTestSuite();

    const seniorDepositAmount = '50000000000000000000';
    const juniorDepositAmount = '10000000000000000000';

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    await voyager.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );

    await voyager.borrow(tus.address, '25000000000000000000', vault.address);
    const poolData = await voyager.getPoolData(tus.address);

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);

    console.log('junior liquidity rate: ', juniorLiquidityRate);
    console.log('senior liquidity rate: ', seniorLiquidityRate);

    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    const poolData1 = await voyager.getPoolData(tus.address);
    const juniorLiquidityRate1 = poolData1.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate1 = poolData1.seniorLiquidityRate.div(RAY);
    console.log('poolData1: ', poolData1);

    console.log('junior liquidity rate: ', juniorLiquidityRate1);
    console.log('senior liquidity rate: ', seniorLiquidityRate1);
  });

  it('Borrow should return correct interest rate', async function () {
    const {
      owner,
      tus,
      seniorDepositToken,
      juniorDepositToken,
      vault,
      voyager,
    } = await setupTestSuite();

    const seniorDepositAmount = '500000000000000000000';
    const juniorDepositAmount = '100000000000000000000';

    await voyager.deposit(tus.address, 0, juniorDepositAmount, owner);
    await voyager.deposit(tus.address, 1, seniorDepositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());

    await voyager.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyager.borrow(tus.address, '100000000000000000000', vault.address);

    const poolData = await voyager.getPoolData(tus.address);
    console.log('total liquidity: ', poolData.totalLiquidity.toString());

    const juniorLiquidityRate = poolData.juniorLiquidityRate.div(RAY);
    const seniorLiquidityRate = poolData.seniorLiquidityRate.div(RAY);
    console.log('junior liquidity rate: ', juniorLiquidityRate.toString());
    console.log('senior liquidity rate: ', seniorLiquidityRate.toString());
  });
});

import { expect } from 'chai';
import { MAX_UINT_256 } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Data Provider', function () {
  it('Get pool data should return correct value', async function () {
    const { crab, weth, voyage } = await setupTestSuite();
    const depositAmount = '100000000000000000000';
    await weth.approve(voyage.address, MAX_UINT_256);
    await voyage.deposit(crab.address, 1, depositAmount);
    const poolData = await voyage.getPoolData(crab.address);
    expect(poolData.seniorLiquidity).to.equal(depositAmount);
  });
});

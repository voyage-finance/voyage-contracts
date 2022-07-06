import { expect } from 'chai';
import { MAX_UINT_256 } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Data Provider', function () {
  it('Get pool data should return correct value', async function () {
    const { owner, tus, voyage } = await setupTestSuite();
    const depositAmount = '100000000000000000000';
    await tus.approve(voyage.address, MAX_UINT_256);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const poolData = await voyage.getPoolData(tus.address);
    expect(poolData.seniorLiquidity).to.equal(depositAmount);
  });
});

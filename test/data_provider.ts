import { expect } from 'chai';
import { MAX_UINT_256 } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Data Provider', function () {
  it('Get pool data should return correct value', async function () {
    const { owner, tus, voyager } = await setupTestSuite();
    const depositAmount = '100000000000000000000';
    await tus.approve(voyager.address, MAX_UINT_256);
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const poolData = await voyager.getPoolData(tus.address);
    expect(poolData.seniorLiquidity).to.equal(depositAmount);
  });
});

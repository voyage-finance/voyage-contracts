import { setupTestSuite } from '../helpers/setupTestSuite';
import { expect } from 'chai';

describe('Reserve Init', function () {
  it('Init reserve twice should revert correct value', async function () {
    const fakeAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
    const { voyager, tus } = await setupTestSuite();
    await expect(
      voyager.initReserve(
        tus.address,
        fakeAddress,
        fakeAddress,
        fakeAddress,
        fakeAddress,
        '500000000000000000000000000'
      )
    ).to.be.revertedWith('cannot initialize twice');
  });

  it('Active reserve should return correct value', async function () {
    const { voyager, tus } = await setupTestSuite();
    const newFlags = await voyager.getReserveFlags(tus.address);
    expect(newFlags[0]).to.equal(true);
  });
});

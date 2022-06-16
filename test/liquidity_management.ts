import { setupTestSuite } from '../helpers/setupTestSuite';
import { expect } from 'chai';

describe('Reserve Init', function () {
  it('Init reserve should return correct value', async function () {
    const fakeAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
    const { voyager, tus } = await setupTestSuite();
    await voyager.initReserve(
      tus.address,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      '500000000000000000000000000'
    );

    // 0 represents junior
    const juniorLiquidityRate = await voyager.liquidityRate(tus.address, '0');
    expect(juniorLiquidityRate).to.equal('0');

    const poolTokens = await voyager.getPoolTokens();
    expect(poolTokens.length).to.equal(1);
    expect(poolTokens[0].symbol).to.equal('TUS');
    expect(poolTokens[0].tokenAddress).to.equal(tus.address);
  });

  it('Active reserve should return correct value', async function () {
    const { voyager, tus } = await setupTestSuite();
    const fakeAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
    voyager.initReserve(
      tus.address,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      fakeAddress,
      '500000000000000000000000000'
    );
    const flags = await voyager.getReserveFlags(tus.address);
    expect(flags[0]).to.equal(false);

    await expect(voyager.activateReserve(tus.address))
      .to.emit(voyager, 'ReserveActivated')
      .withArgs(tus.address);
    const newFlags = await voyager.getReserveFlags(tus.address);
    expect(newFlags[0]).to.equal(true);
  });
});

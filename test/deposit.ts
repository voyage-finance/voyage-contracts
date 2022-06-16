import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe.only('Reserve Deposit', function () {
  it('Deposit junior liquidity should return correct value', async function () {
    const { owner, juniorDepositToken, tus, voyager } = await setupTestSuite();
    const depositAmount = '1000000000000000000';
    await expect(voyager.deposit(tus.address, 0, depositAmount, owner))
      .to.emit(voyager, 'Deposit')
      .withArgs(tus.address, owner, 0, depositAmount);
    const juniorTokenAmount = await juniorDepositToken.balanceOf(owner);
    expect(juniorTokenAmount).to.equal(ethers.BigNumber.from(depositAmount));

    // deposit again
    await expect(voyager.deposit(tus.address, 0, depositAmount, owner))
      .to.emit(voyager, 'Deposit')
      .withArgs(tus.address, owner, 0, depositAmount);
    expect(await voyager.liquidityRate(tus.address, '0')).to.equal('0');
  });

  it('Deposit senior liquidity should return correct value', async function () {
    const { owner, seniorDepositToken, tus, voyager } = await setupTestSuite();
    const depositAmount = '1000000000000000000';
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const seniorTokenAmount = await seniorDepositToken.balanceOf(owner);
    expect(seniorTokenAmount).to.equal(ethers.BigNumber.from(depositAmount));

    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
    // deposit again
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    expect(await voyager.liquidityRate(tus.address, '1')).to.equal('0');
  });
});

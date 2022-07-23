import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Reserve Deposit', function () {
  it('Deposit junior liquidity should return correct value', async function () {
    const { owner, juniorDepositToken, tus, voyage } = await setupTestSuite();
    const depositAmount = '1000000000000000000';
    await expect(voyage.deposit(tus.address, 0, depositAmount))
      .to.emit(voyage, 'Deposit')
      .withArgs(tus.address, owner, 0, depositAmount);
    const juniorTokenAmount = await juniorDepositToken.balanceOf(owner);
    expect(juniorTokenAmount).to.equal(ethers.BigNumber.from(depositAmount));

    // deposit again
    await expect(voyage.deposit(tus.address, 0, depositAmount))
      .to.emit(voyage, 'Deposit')
      .withArgs(tus.address, owner, 0, depositAmount);
  });

  it('Deposit senior liquidity should return correct value', async function () {
    const { owner, seniorDepositToken, tus, voyage } = await setupTestSuite();
    const depositAmount = '1000000000000000000';
    await voyage.deposit(tus.address, 1, depositAmount);
    const seniorTokenAmount = await seniorDepositToken.balanceOf(owner);
    expect(seniorTokenAmount).to.equal(ethers.BigNumber.from(depositAmount));

    // deposit again
    await voyage.deposit(tus.address, 1, depositAmount);
  });
});

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { decimals, MAX_UINT_256 } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Withdraw', function () {
  it('Withdraw with no interest should return correct value', async function () {
    const { voyage, seniorDepositToken, juniorDepositToken, tus, owner } =
      await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(tus.address, 1, amount, owner);
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    // @ts-expect-error
    await ethers.provider.send('evm_mine');

    const accumulatedBalance = await seniorDepositToken.balanceOf(owner);
    expect(accumulatedBalance.toString()).to.equal('100000000000000000000');
    console.log('balance: ', accumulatedBalance);

    await voyage.withdraw(tus.address, 1, '10000000000000000000', owner);

    const accumulatedBalanceAfter = await seniorDepositToken.balanceOf(owner);
    await expect(accumulatedBalanceAfter.toString()).to.equal(
      '90000000000000000000'
    );
  });

  it('Withdraw with interest should return correct value', async function () {
    const { voyage, seniorDepositToken, juniorDepositToken, tus, owner } =
      await setupTestSuite();
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(tus.address, 1, amount, owner);
    const vault = await voyage.getVaultAddr(owner);
    await voyage.depositMargin(vault, tus.address, '100000000000000000000');
    await voyage.borrow(tus.address, '10000000000000000000', vault);
    await voyage.borrow(tus.address, '10000000000000000000', vault);
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    // @ts-ignore
    await ethers.provider.send('evm_mine');

    const originalBalance = await tus.balanceOf(owner);
    console.log('original balance: ', originalBalance.toString());

    const accumulatedBalance = await seniorDepositToken.balanceOf(owner);
    console.log('accumulated balance: ', accumulatedBalance.toString());
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await voyage.withdraw(tus.address, 1, '10000000000000000000', owner);
    const accumulatedBalanceAfter = await seniorDepositToken.balanceOf(owner);
    console.log(
      'cumulated balance after withdrawing: ',
      accumulatedBalanceAfter
    );

    const updatedBalance = await tus.balanceOf(owner);
    console.log('updated balance: ', updatedBalance.toString());
  });

  it('maxWithdraw should exclude unbonding amount', async function () {
    const { voyage, tus, seniorDepositToken, juniorDepositToken, owner } =
      await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(tus.address, 1, amount, owner);
    await voyage.withdraw(tus.address, 1, amount, owner);
    const balance = await voyage.balance(tus.address, owner, 1);
    const shares = await seniorDepositToken.balanceOf(owner);
    const unbonding = await voyage.unbonding(tus.address, owner, 1);

    expect(balance).to.equal(ethers.BigNumber.from(0));
    expect(shares).to.equal(ethers.BigNumber.from(0));
    expect(unbonding).to.equal(amount);
  });
});

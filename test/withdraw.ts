import { expect } from 'chai';
import { deployments, ethers, getNamedAccounts } from 'hardhat';
import { decimals, MAX_UINT_256 } from '../helpers/math';
import { setupWithdrawalTestSuite } from '../helpers/withdraw';
import { LiquidityManager } from '../typechain/LiquidityManager';
import { Voyager } from '../typechain/Voyager';

describe('Withdraw', function () {
  it('Withdraw with no interest should return correct value', async function () {
    const { voyager, seniorDepositToken, tus, owner } =
      await setupWithdrawalTestSuite();
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyager.deposit(tus.address, 1, amount);
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    // @ts-expect-error
    await ethers.provider.send('evm_mine');

    const accumulatedBalance = await seniorDepositToken.balanceOf(owner);
    await expect(accumulatedBalance.toString()).to.equal(
      '100000000000000000000'
    );

    await voyager.withdraw(tus.address, 1, '10000000000000000000');

    const accumulatedBalanceAfter = await seniorDepositToken.balanceOf(owner);
    await expect(accumulatedBalanceAfter.toString()).to.equal(
      '90000000000000000000'
    );
  });

  it('Withdraw with interest should return correct value', async function () {
    const { voyager, seniorDepositToken, tus, vaultAddr, owner } =
      await setupWithdrawalTestSuite();
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyager.deposit(tus.address, 1, amount);
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0);
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0);
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    // @ts-ignore
    await ethers.provider.send('evm_mine');

    const originalBalance = await tus.balanceOf(owner);
    console.log('original balance: ', originalBalance.toString());

    const accumulatedBalance = await seniorDepositToken.balanceOf(owner);
    console.log('accumulated balance: ', accumulatedBalance.toString());
    await voyager.withdraw(tus.address, 1, '10000000000000000000');
    const accumulatedBalanceAfter = await seniorDepositToken.balanceOf(owner);
    console.log(
      'cumulated balance after withdrawing: ',
      accumulatedBalanceAfter
    );

    const updatedBalance = await tus.balanceOf(owner);
    console.log('updated balance: ', updatedBalance.toString());
  });

  it('maxWithdraw should exclude unbonding amount', async function () {
    const { voyager, tus, liquidityManager, seniorDepositToken, owner } =
      await setupWithdrawalTestSuite();
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyager.deposit(tus.address, 1, amount);
    await voyager.withdraw(tus.address, 1, amount);
    const balance = await liquidityManager.balance(tus.address, owner, 1);
    const shares = await seniorDepositToken.balanceOf(owner);
    const unbonding = await liquidityManager.unbonding(tus.address, owner, 1);

    expect(balance).to.equal(ethers.BigNumber.from(0));
    expect(shares).to.equal(ethers.BigNumber.from(0));
    expect(unbonding).to.equal(amount);
  });
});

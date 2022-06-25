import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';
import { setupTestSuiteWithMocks } from '../helpers/setupTestSuite';

describe('SeniorDepositToken', async () => {
  it('totalAssets should return underlying balance when there is no outstanding debt', async () => {
    const { seniorDepositToken, underlying, decimals } =
      await setupTestSuiteWithMocks({ principalBalance: 0 });
    const amount = ethers.BigNumber.from(100).mul(decimals);
    await underlying.transfer(seniorDepositToken.address, amount);
    const totalAssets = await seniorDepositToken.totalAssets();
    expect(totalAssets).to.equal(amount);
  });

  it('totalAssets should include principal balance only', async () => {
    const principalBalance = 100;
    const interestBalance = 100;
    const { seniorDepositToken, underlying, decimals } =
      await setupTestSuiteWithMocks({
        principalBalance,
        interestBalance,
      });

    const underlyingBalance = ethers.BigNumber.from(100).mul(decimals);
    await underlying.transfer(seniorDepositToken.address, underlyingBalance);

    const totalAssets = await seniorDepositToken.totalAssets();
    expect(totalAssets).to.equal(
      underlyingBalance.add(
        ethers.BigNumber.from(principalBalance).mul(decimals)
      )
    );
  });

  it('exchange rate goes up when underlying balance goes up', async () => {
    const { seniorDepositToken, underlying, decimals } =
      await setupTestSuiteWithMocks();
    const { owner } = await getNamedAccounts();

    await underlying.approve(seniorDepositToken.address, MAX_UINT_256);
    // deposit some tokens
    await seniorDepositToken.deposit(
      ethers.BigNumber.from(100).mul(decimals),
      owner
    );

    // simulate interest repayment
    await underlying.transfer(
      seniorDepositToken.address,
      ethers.BigNumber.from(20).mul(decimals)
    );

    const underlyingBalance = await seniorDepositToken.maxWithdraw(owner);
    expect(underlyingBalance).to.equal(
      ethers.BigNumber.from(100 + 20).mul(decimals)
    );
  });

  it('should use msg.sender as depositor when calling deposit directly', async () => {
    const { seniorDepositToken, underlying, decimals } =
      await setupTestSuiteWithMocks();
    const { owner } = await getNamedAccounts();
    await underlying.approve(seniorDepositToken.address, MAX_UINT_256);
    await seniorDepositToken.deposit(
      ethers.BigNumber.from(100).mul(decimals),
      owner
    );
    const balance = await seniorDepositToken.maxWithdraw(owner);
    expect(balance).to.equal(ethers.BigNumber.from(100).mul(decimals));
  });
});

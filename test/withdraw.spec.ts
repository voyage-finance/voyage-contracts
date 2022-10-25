import { BigNumber } from 'ethers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { decimals, MAX_UINT_256 } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';
import { WAD } from '@helpers/constants';

describe('Withdraw', function () {
  it('Withdraw with invalid amount should revert', async function () {
    const { voyage, seniorDepositToken, crab, owner } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 1, amount);
    await expect(
      seniorDepositToken.withdraw(toWad(200), owner, owner)
    ).to.revertedWithCustomError(seniorDepositToken, 'InsufficientBalance');
  });

  it('Redeem with invalid amount should revert', async function () {
    const { voyage, seniorDepositToken, crab, owner } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 1, amount);
    await expect(
      seniorDepositToken.redeem(toWad(200), owner, owner)
    ).to.revertedWithCustomError(seniorDepositToken, 'InsufficientBalance');
  });

  it('Withdraw with no interest should return correct value', async function () {
    const { voyage, seniorDepositToken, juniorDepositToken, crab, owner } =
      await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 1, amount);
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    // @ts-expect-error
    await ethers.provider.send('evm_mine');

    const accumulatedBalance = await seniorDepositToken.balanceOf(owner);
    expect(accumulatedBalance.toString()).to.equal('100000000000000000000');
    console.log('balance: ', accumulatedBalance);

    await voyage.withdraw(crab.address, 1, '10000000000000000000');

    const accumulatedBalanceAfter = await seniorDepositToken.balanceOf(owner);
    await expect(accumulatedBalanceAfter.toString()).to.equal(
      '90000000000000000000'
    );
  });

  it('withdraw senior token through voyage should return correct value', async function () {
    const {
      voyage,
      crab,
      weth,
      seniorDepositToken,
      juniorDepositToken,
      owner,
    } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 1, amount);
    await voyage.withdraw(crab.address, 1, amount);
    const balance = await voyage.balance(crab.address, owner, 1);
    const shares = await seniorDepositToken.balanceOf(owner);
    const unbonding = await voyage.unbonding(crab.address, owner);
    const maxRedeem = await seniorDepositToken.maxRedeem(owner);
    const maxWithdraw = await seniorDepositToken.maxWithdraw(owner);
    const maxClaimable = await seniorDepositToken.maximumClaimable(owner);
    const totalUnbondingAsset = await seniorDepositToken.totalUnbondingAsset();

    expect(balance).to.equal(ethers.BigNumber.from('0'));
    expect(shares).to.equal(ethers.BigNumber.from('0'));
    expect(unbonding).to.equal(amount);
    expect(maxRedeem).to.equal(ethers.BigNumber.from('0'));
    expect(maxWithdraw).to.equal(ethers.BigNumber.from('0'));
    expect(maxClaimable).to.equal(amount);
    expect(totalUnbondingAsset).to.equal(amount);

    const balanceBeforeClaim = await weth.balanceOf(owner);
    await seniorDepositToken.claim();
    const balanceAfterClaim = await weth.balanceOf(owner);
    expect(balanceAfterClaim.sub(balanceBeforeClaim)).to.equal(amount);

    const maxClaimableAfterClaim = await seniorDepositToken.maximumClaimable(
      owner
    );
    expect(maxClaimableAfterClaim).to.equal(0);

    const totalUnbondingAssetAfter =
      await seniorDepositToken.totalUnbondingAsset();
    expect(totalUnbondingAssetAfter).to.equal(0);
  });

  it('withdraw senior token through voyage should return correct value', async function () {
    const {
      voyage,
      crab,
      weth,
      seniorDepositToken,
      juniorDepositToken,
      owner,
    } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 1, amount);
    await voyage.withdraw(crab.address, 1, amount);
    const balance = await voyage.balance(crab.address, owner, 1);
    const shares = await seniorDepositToken.balanceOf(owner);
    const unbonding = await voyage.unbonding(crab.address, owner);
    const maxRedeem = await seniorDepositToken.maxRedeem(owner);
    const maxWithdraw = await seniorDepositToken.maxWithdraw(owner);
    const maxClaimable = await seniorDepositToken.maximumClaimable(owner);
    const totalUnbondingAsset = await seniorDepositToken.totalUnbondingAsset();

    expect(balance).to.equal(ethers.BigNumber.from('0'));
    expect(shares).to.equal(ethers.BigNumber.from('0'));
    expect(unbonding).to.equal(amount);
    expect(maxRedeem).to.equal(ethers.BigNumber.from('0'));
    expect(maxWithdraw).to.equal(ethers.BigNumber.from('0'));
    expect(maxClaimable).to.equal(amount);
    expect(totalUnbondingAsset).to.equal(amount);

    const balanceBeforeClaim = await weth.balanceOf(owner);
    await seniorDepositToken.claim();
    const balanceAfterClaim = await weth.balanceOf(owner);
    expect(balanceAfterClaim.sub(balanceBeforeClaim)).to.equal(amount);

    const maxClaimableAfterClaim = await seniorDepositToken.maximumClaimable(
      owner
    );
    expect(maxClaimableAfterClaim).to.equal(0);

    const totalUnbondingAssetAfter =
      await seniorDepositToken.totalUnbondingAsset();
    expect(totalUnbondingAssetAfter).to.equal(0);
  });

  it('withdraw senior token with insufficient underlying asset should return correct value', async function () {
    const {
      voyage,
      crab,
      weth,
      seniorDepositToken,
      juniorDepositToken,
      owner,
      priceOracle,
      marketPlace,
      purchaseDataFromLooksRare,
      reserveConfiguration,
    } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 0, amount);
    await voyage.deposit(crab.address, 1, amount);

    const maxWithdrawBefore = await seniorDepositToken.maxWithdraw(owner);
    console.log('max withdraw before buyNow: ', maxWithdrawBefore.toString());
    const sharesBefore = await seniorDepositToken.balanceOf(owner);
    expect(sharesBefore).to.equal(amount);

    // to reduce underlying asset
    const floor = ethers.BigNumber.from(10).mul(WAD);
    await priceOracle.updateTwap(crab.address, floor);
    const vault = await voyage.getVault(owner);
    const underlyingAssetBeforeBuyNow = await weth.balanceOf(
      seniorDepositToken.address
    );
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );

    const underlyingAssetAfterBuyNow = await weth.balanceOf(
      seniorDepositToken.address
    );

    const actualUnderlyingBorrowed = underlyingAssetBeforeBuyNow.sub(
      underlyingAssetAfterBuyNow
    );

    const { term, epoch, incomeRatio } = reserveConfiguration;
    const nper = term / epoch;

    const loan = await voyage.getLoanDetail(vault, crab.address, 0);
    const seniorInterest = loan.pmt.interest.percentMul(incomeRatio);
    const expectedBorrow = loan.principal
      .sub(loan.principal.div(nper))
      .sub(seniorInterest);

    expect(actualUnderlyingBorrowed).to.equal(expectedBorrow);

    const maxWithdrawAfter = await seniorDepositToken.maxWithdraw(owner);
    expect(maxWithdrawAfter).to.equal(
      amount.add(loan.interest.percentMul(incomeRatio))
    );

    await seniorDepositToken.withdraw(maxWithdrawAfter, owner, owner);
    const sharesAfter = await seniorDepositToken.balanceOf(owner);
    expect(sharesAfter).to.equal(0);

    // 100 - 66.667 + 075
    const maxClaimable = await seniorDepositToken.maximumClaimable(owner);
    expect(maxClaimable).to.equal(underlyingAssetAfterBuyNow);

    const balanceBeforeClaim = await weth.balanceOf(owner);
    await seniorDepositToken.claim();
    const balanceAfterClaim = await weth.balanceOf(owner);
    expect(balanceAfterClaim.sub(balanceBeforeClaim)).to.equal(maxClaimable);
    expect(await seniorDepositToken.maximumClaimable(owner)).to.equal(0);
  });

  it('withdraw senior token with sufficient underlying asset should return correct value', async function () {
    const {
      voyage,
      crab,
      weth,
      seniorDepositToken,
      juniorDepositToken,
      owner,
      priceOracle,
      marketPlace,
      purchaseDataFromLooksRare,
      reserveConfiguration,
    } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 0, amount);
    await voyage.deposit(crab.address, 1, amount);

    const maxWithdrawBefore = await seniorDepositToken.maxWithdraw(owner);
    console.log('max withdraw before buyNow: ', maxWithdrawBefore.toString());
    const sharesBefore = await seniorDepositToken.balanceOf(owner);
    expect(sharesBefore).to.equal(amount);

    // to reduce underlying asset
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );

    const { incomeRatio } = reserveConfiguration;
    const loan = await voyage.getLoanDetail(vault, crab.address, 0);
    const maxWithdrawAfter = await seniorDepositToken.maxWithdraw(owner);
    // underlying balance + total outstanding principal + (total outstanding interest)
    // which is total principal + total interest
    // 100(principal) + 0.075(interest)
    const totalSeniorInterest = loan.interest.percentMul(incomeRatio);
    const totalAssetsExpected = amount.add(totalSeniorInterest);
    expect(maxWithdrawAfter).to.equal(totalAssetsExpected);

    await seniorDepositToken.withdraw(maxWithdrawAfter, owner, owner);
    const sharesAfter = await seniorDepositToken.balanceOf(owner);
    expect(sharesAfter).to.equal(0);

    // 100 - 66.667 + 0.075
    const maxClaimable = await seniorDepositToken.maximumClaimable(owner);
    const cashBalance = await weth.balanceOf(seniorDepositToken.address);
    expect(maxClaimable).to.equal(cashBalance);

    const maxWithdrawBeforeTransfer = await seniorDepositToken.maxWithdraw(
      owner
    );
    expect(maxWithdrawBeforeTransfer).to.equal(0);

    await weth.transfer(seniorDepositToken.address, toWad(100));
    const maxWithdrawAfterTransfer = await seniorDepositToken.maxWithdraw(
      owner
    );
    expect(maxWithdrawAfterTransfer).to.equal(0);

    let maxClaimableAfter = await seniorDepositToken.maximumClaimable(owner);
    expect(maxClaimableAfter).to.equal(totalAssetsExpected);

    // transfer again
    await weth.transfer(seniorDepositToken.address, toWad(100));
    maxClaimableAfter = await seniorDepositToken.maximumClaimable(owner);
    expect(maxClaimableAfter).to.equal(totalAssetsExpected);

    const balanceBeforeClaim = await weth.balanceOf(owner);
    await seniorDepositToken.claim();
    const balanceAfterClaim = await weth.balanceOf(owner);
    expect(balanceAfterClaim.sub(balanceBeforeClaim)).to.equal(
      totalAssetsExpected
    );
  });

  it('totalUnbondingAsset should return correct vaule in the case of default', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(100));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    await increase(41);
    const updatedNftPrice = toWad(1);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await seniorDepositToken.withdraw(toWad(120), owner, owner);
    const totalUnbondingAssetBefore =
      await seniorDepositToken.totalUnbondingAsset();
    const totalAssetBefore = await seniorDepositToken.totalAssets();
    console.log('totalAssetBefore: ', totalAssetBefore.toString());
    console.log(
      'totalUnbondingAssetBefore: ',
      totalUnbondingAssetBefore.toString()
    );
    const balanceOfBefore = await seniorDepositToken.balanceOf(owner);
    console.log('balanceOfBefore: ', balanceOfBefore.toString());
    // liquidate and write down
    await voyage.liquidate(crab.address, vault, 0);
    const totalAssetAfter = await seniorDepositToken.totalAssets();
    const totalUnbongdingAssetAfter =
      await seniorDepositToken.totalUnbondingAsset();
    const balanceOfAfter = await seniorDepositToken.balanceOf(owner);
    console.log('totalAssetAfter: ', totalAssetAfter.toString());
    console.log(
      'totalUnbongdingAssetAfter: ',
      totalUnbongdingAssetAfter.toString()
    );
    console.log('balanceOfAfter: ', balanceOfAfter.toString());
    expect(totalUnbongdingAssetAfter).to.lt(totalUnbondingAssetBefore);
  });

  it('totalUnbondingAsset should return correct vaule when liquidation vaule grate than debt', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(100));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    await increase(41);
    const updatedNftPrice = toWad(200);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await seniorDepositToken.withdraw(toWad(120), owner, owner);
    const totalUnbondingAssetBefore =
      await seniorDepositToken.totalUnbondingAsset();
    // liquidate and no write down
    await voyage.liquidate(crab.address, vault, 0);
    const totalUnbongdingAssetAfter =
      await seniorDepositToken.totalUnbondingAsset();
    expect(totalUnbongdingAssetAfter).to.eq(totalUnbondingAssetBefore);
  });
});

async function increase(n: number) {
  const days = n * 24 * 60 * 60;
  await ethers.provider.send('evm_increaseTime', [days]);
  await ethers.provider.send('evm_mine', []);
}

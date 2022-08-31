import { expect } from 'chai';
import { ethers } from 'hardhat';
import { decimals, MAX_UINT_256 } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';

describe('Withdraw', function () {
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

  it('Withdraw with interest should return correct value', async function () {
    const {
      voyage,
      seniorDepositToken,
      juniorDepositToken,
      weth,
      crab,
      owner,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 1, amount);
    const vault = await voyage.getVaultAddr(owner);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    // @ts-ignore
    await ethers.provider.send('evm_mine');

    const originalBalance = await weth.balanceOf(owner);
    console.log('original balance: ', originalBalance.toString());

    const accumulatedBalance = await seniorDepositToken.balanceOf(owner);
    console.log('accumulated balance: ', accumulatedBalance.toString());
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await voyage.withdraw(crab.address, 1, '10000000000000000000');
    const accumulatedBalanceAfter = await seniorDepositToken.balanceOf(owner);
    console.log(
      'cumulated balance after withdrawing: ',
      accumulatedBalanceAfter
    );

    const updatedBalance = await weth.balanceOf(owner);
    console.log('updated balance: ', updatedBalance.toString());
  });

  it('withdraw senior token should return correct value', async function () {
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
    const unbonding = await voyage.unbonding(crab.address, owner, 1);
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
    } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
    await voyage.deposit(crab.address, 1, amount);

    const maxWithdrawBefore = await seniorDepositToken.maxWithdraw(owner);
    console.log('max withdraw before buyNow: ', maxWithdrawBefore.toString());
    const sharesBefore = await seniorDepositToken.balanceOf(owner);
    expect(sharesBefore).to.equal(amount);

    // to reduce underlying asset
    await priceOracle.updateTwap(crab.address, toWad(10));
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

    // principal: 33.333
    // interest: 0.15（* 0.5）
    // underlyingAssetAfterBuyNow = underlyingAssetBeforeBuyNow - outsanding principal + interest
    // outsanding principal = underlyingAssetBeforeBuyNow + interest - underlyingAssetAfterBuyNow
    const underlyingAssetBorrowed = underlyingAssetBeforeBuyNow
      .sub(underlyingAssetAfterBuyNow)
      .add(toWad(0.075));

    expect(underlyingAssetBorrowed).to.equal('6666666666666666667');

    const maxWithdrawAfter = await seniorDepositToken.maxWithdraw(owner);
    // underlying balance + total outstanding principal + total outstanding senior interest
    // which is total principal + total interest
    // 100(principal) + 0.075(interest)
    expect(maxWithdrawAfter).to.equal(toWad(100.075));

    await seniorDepositToken.withdraw(maxWithdrawAfter, owner, owner);
    const sharesAfter = await seniorDepositToken.balanceOf(owner);
    expect(sharesAfter).to.equal(0);

    // 100 - 66.667 + 075
    const maxClaimable = await seniorDepositToken.maximumClaimable(owner);
    expect(maxClaimable).to.equal('93408333333333333333');

    const balanceBeforeClaim = await weth.balanceOf(owner);
    await seniorDepositToken.claim();
    const balanceAfterClaim = await weth.balanceOf(owner);
    expect(balanceAfterClaim.sub(balanceBeforeClaim)).to.equal(
      '93408333333333333333'
    );
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
    } = await setupTestSuite();
    await seniorDepositToken.approve(voyage.address, MAX_UINT_256);
    await juniorDepositToken.approve(voyage.address, MAX_UINT_256);
    const amount = ethers.BigNumber.from(100).mul(decimals(18));
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

    const maxWithdrawAfter = await seniorDepositToken.maxWithdraw(owner);
    // underlying balance + total outstanding principal + (total outstanding interest)
    // which is total principal + total interest
    // 100(principal) + 0.075(interest)
    expect(maxWithdrawAfter).to.equal(toWad(100.075));

    await seniorDepositToken.withdraw(maxWithdrawAfter, owner, owner);
    const sharesAfter = await seniorDepositToken.balanceOf(owner);
    expect(sharesAfter).to.equal(0);

    // 100 - 66.667 + 0.075
    const maxClaimable = await seniorDepositToken.maximumClaimable(owner);
    expect(maxClaimable).to.equal('93408333333333333333');

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
    expect(maxClaimableAfter).to.equal(toWad(100.075));

    // transfer again
    await weth.transfer(seniorDepositToken.address, toWad(100));
    maxClaimableAfter = await seniorDepositToken.maximumClaimable(owner);
    expect(maxClaimableAfter).to.equal(toWad(100.075));

    const balanceBeforeClaim = await weth.balanceOf(owner);
    await seniorDepositToken.claim();
    const balanceAfterClaim = await weth.balanceOf(owner);
    expect(balanceAfterClaim.sub(balanceBeforeClaim)).to.equal(toWad(100.075));
  });
});

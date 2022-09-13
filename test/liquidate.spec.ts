import { BigNumber } from 'ethers';
import { expect } from 'chai';
import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { toRay2, toWad } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
import {
  calculateEffectiveInterestRate,
  getDownpaymentJuniorInterest,
  getOutstandingJuniorInterest,
  getOutstandingProtocolFee,
  getOutstandingSeniorInterest,
} from './helpers/utils/calculations';

describe('Liquidate', function () {
  it('Liquidate a invalid debt should revert', async function () {
    const {
      owner,
      priceOracle,
      crab,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.deposit(crab.address, 0, depositAmount);
    await voyage.deposit(crab.address, 1, depositAmount);

    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      '1',
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );

    // repay the first draw down
    await voyage.repay(crab.address, 0, vault);

    // try to liquidate
    await expect(
      voyage.liquidate(crab.address, vault, 0)
    ).to.be.revertedWithCustomError(voyage, 'InvalidLiquidate');
  });

  it('Invalid floor price should revert', async function () {
    const {
      owner,
      priceOracle,
      crab,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.deposit(crab.address, 0, depositAmount);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      '1',
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await increase(51);

    // try to liquidate
    await priceOracle.updateTwap(crab.address, toWad(0));
    await expect(
      voyage.liquidate(crab.address, vault, 1)
    ).to.be.revertedWithCustomError(voyage, 'InvalidFloorPrice');
  });

  it('Outdated floor price should revert', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);
    await voyage.setMaxTwapStaleness(crab.address, 100);

    // epoch + grace period
    await increase(41);
    await expect(
      voyage.liquidate(crab.address, vault, 0)
    ).to.be.revertedWithCustomError(voyage, 'LiquidateStaleTwap');
  });

  it('Liquidate with 0 max twap staleness should revert', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);
    await voyage.setMaxTwapStaleness(crab.address, 0);

    // epoch + grace period
    await increase(41);
    await expect(
      voyage.liquidate(crab.address, vault, 0)
    ).to.be.revertedWithCustomError(voyage, 'LiquidateStaleTwap');
  });

  it('Just staled floor price should revert', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);
    await voyage.setMaxTwapStaleness(crab.address, 41 * 24 * 60 * 60);

    // epoch + grace period
    await increase(41);
    await expect(
      voyage.liquidate(crab.address, vault, 0)
    ).to.be.revertedWithCustomError(voyage, 'LiquidateStaleTwap');
  });

  it('Valid liquidate with nft should return correct value', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);
    const days = 42 * 24 * 60 * 60;
    await voyage.setMaxTwapStaleness(crab.address, days);

    // epoch + grace period
    await increase(41);
    await voyage.liquidate(crab.address, vault, 0);
    await expect(await crab.ownerOf(1)).to.equal(owner);
  });

  it('Liquidation proceeds not enough to repay principal completely should return correct value (junior tranche can cover debt)', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
      juniorDepositToken,
      reserveConfiguration,
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
    const nftPrice = BigNumber.from(toWad(10));
    await priceOracle.updateTwap(crab.address, nftPrice.toString());

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);

    const updatedNftPrice = toWad(1);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);

    const nper = reserveConfiguration.term / reserveConfiguration.epoch;
    const downpayment = nftPrice.div(nper);
    const totalDebt = nftPrice.sub(downpayment);
    const discountedFloorPrice = await getDiscountedFloorPrice(
      BigNumber.from(updatedNftPrice),
      reserveConfiguration.liquidationBonus
    );
    expect(discountedFloorPrice).to.lt(totalDebt);

    // calculate effective interest rate
    const effectiveInterestRate = calculateEffectiveInterestRate(
      BigNumber.from(reserveConfiguration.epoch),
      BigNumber.from(nper),
      BigNumber.from(toRay2(reserveConfiguration.baseRate))
    );
    const outstandingSeniorInterest = getOutstandingSeniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const outstandingJuniorInterest = getOutstandingJuniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const juniorDownpaymentInterest = getDownpaymentJuniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const maybeWritedownPrincipalAmount = totalDebt.sub(discountedFloorPrice);
    const juniorBalanceAtTheMonmentOfLiquidate = BigNumber.from(
      juniorDeposit
    ).add(juniorDownpaymentInterest);
    expect(maybeWritedownPrincipalAmount).to.lt(
      juniorBalanceAtTheMonmentOfLiquidate
    );

    expect(seniorTotalAssetBefore.toString()).to.eq(
      seniorTotalAssetAfter.add(outstandingSeniorInterest)
    );
    const subtractJuniorTrancheAmount = maybeWritedownPrincipalAmount.add(
      outstandingJuniorInterest
    );
    expect(juniorTotalAssetAfter.add(subtractJuniorTrancheAmount)).to.eq(
      juniorTotalAssetBefore
    );
  });

  it('Liquidation proceeds not enough to repay principal completely should return correct value (junior tranche can not cover debt)', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
      juniorDepositToken,
      reserveConfiguration,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(5);
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
    const nftPrice = BigNumber.from(toWad(10));
    await priceOracle.updateTwap(crab.address, nftPrice.toString());

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);

    const updatedNftPrice = toWad(1);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);

    const nper = reserveConfiguration.term / reserveConfiguration.epoch;
    const downpayment = nftPrice.div(nper);
    const totalDebt = nftPrice.sub(downpayment);
    const discountedFloorPrice = await getDiscountedFloorPrice(
      BigNumber.from(updatedNftPrice),
      reserveConfiguration.liquidationBonus
    );
    expect(discountedFloorPrice).to.lt(totalDebt);

    const effectiveInterestRate = calculateEffectiveInterestRate(
      BigNumber.from(reserveConfiguration.epoch),
      BigNumber.from(nper),
      BigNumber.from(toRay2(reserveConfiguration.baseRate))
    );
    const outstandingSeniorInterest = getOutstandingSeniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const outstandingJuniorInterest = getOutstandingJuniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const juniorDownpaymentInterest = getDownpaymentJuniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const maybeWritedownPrincipalAmount = totalDebt.sub(discountedFloorPrice);
    const juniorBalanceAtTheMonmentOfLiquidate = BigNumber.from(
      juniorDeposit
    ).add(juniorDownpaymentInterest);
    expect(maybeWritedownPrincipalAmount).to.gt(
      juniorBalanceAtTheMonmentOfLiquidate
    );
    const writeDownPrincipaAmount = maybeWritedownPrincipalAmount.sub(
      juniorBalanceAtTheMonmentOfLiquidate
    );

    expect(seniorTotalAssetBefore.toString()).to.eq(
      seniorTotalAssetAfter
        .add(outstandingSeniorInterest)
        .add(writeDownPrincipaAmount)
    );
    expect(juniorTotalAssetAfter).to.eq(0);
  });

  it('Liquidation proceeds enough to repay principal partially should return correct value', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
      juniorDepositToken,
      reserveConfiguration,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    await increase(41);
    const nftPrice = BigNumber.from(toWad(10));
    await priceOracle.updateTwap(crab.address, nftPrice);

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    const updatedNftPrice = toWad(7.1);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);

    const nper = reserveConfiguration.term / reserveConfiguration.epoch;
    const downpayment = nftPrice.div(nper);
    const totalDebt = nftPrice.sub(downpayment);
    const discountedFloorPrice = await getDiscountedFloorPrice(
      BigNumber.from(updatedNftPrice),
      reserveConfiguration.liquidationBonus
    );

    // calculate effective interest rate
    const effectiveInterestRate = calculateEffectiveInterestRate(
      BigNumber.from(reserveConfiguration.epoch),
      BigNumber.from(nper),
      BigNumber.from(toRay2(reserveConfiguration.baseRate))
    );
    const outstandingSeniorInterest = getOutstandingSeniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const outstandingJuniorInterest = getOutstandingJuniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const maybeRepayToSeniorInterest = discountedFloorPrice.sub(totalDebt);
    expect(maybeRepayToSeniorInterest).to.lt(outstandingSeniorInterest);
    const writedownSeniorInterest = outstandingSeniorInterest.sub(
      maybeRepayToSeniorInterest
    );

    expect(seniorTotalAssetBefore.toString()).to.eq(
      seniorTotalAssetAfter.add(writedownSeniorInterest)
    );
    expect(juniorTotalAssetBefore.toString()).to.eq(
      juniorTotalAssetAfter.add(outstandingJuniorInterest)
    );
  });

  it('Liquidation proceeds enough to repay principal and seniorTrancheInterest completely, and juniorTrancheInterest partially should return correct value', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
      juniorDepositToken,
      reserveConfiguration,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    await increase(41);
    const nftPrice = BigNumber.from(toWad(10));
    await priceOracle.updateTwap(crab.address, nftPrice);

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    const updatedNftPrice = toWad(7.2);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);

    const nper = reserveConfiguration.term / reserveConfiguration.epoch;
    const downpayment = nftPrice.div(nper);
    const totalDebt = nftPrice.sub(downpayment);
    const discountedFloorPrice = await getDiscountedFloorPrice(
      BigNumber.from(updatedNftPrice),
      reserveConfiguration.liquidationBonus
    );

    // calculate effective interest rate
    const effectiveInterestRate = calculateEffectiveInterestRate(
      BigNumber.from(reserveConfiguration.epoch),
      BigNumber.from(nper),
      BigNumber.from(toRay2(reserveConfiguration.baseRate))
    );
    const outstandingSeniorInterest = getOutstandingSeniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const outstandingJuniorInterest = getOutstandingJuniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const maybeRepayToSeniorInterest = discountedFloorPrice.sub(totalDebt);
    expect(maybeRepayToSeniorInterest).to.gt(outstandingSeniorInterest);
    const maybeRepayToJuniorInterest = maybeRepayToSeniorInterest.sub(
      outstandingJuniorInterest
    );
    expect(maybeRepayToJuniorInterest).to.gt(0);
    const writedownJuniorInterest = outstandingJuniorInterest.sub(
      maybeRepayToJuniorInterest
    );

    expect(seniorTotalAssetBefore.toString()).to.eq(seniorTotalAssetAfter);
    expect(juniorTotalAssetBefore.toString()).to.eq(
      juniorTotalAssetAfter.add(writedownJuniorInterest)
    );
  });

  it('Liquidation proceeds enough to repay principal, seniorTrancheInterest and juniorTrancheInterest completely, and fees partially should return correct value', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
      juniorDepositToken,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    await increase(41);
    const nftPrice = BigNumber.from(toWad(10));
    await priceOracle.updateTwap(crab.address, nftPrice);

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    const updatedNftPrice = toWad(7.4);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);

    expect(seniorTotalAssetBefore.toString()).to.eq(seniorTotalAssetAfter);
    expect(juniorTotalAssetBefore.toString()).to.eq(juniorTotalAssetAfter);
  });

  it('Liquidation proceeds enough to repay everything with remaining funds > 0 -- should transfer remainder to the vault', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      seniorDepositToken,
      juniorDepositToken,
      weth,
      reserveConfiguration,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    await increase(41);
    const nftPrice = BigNumber.from(toWad(10));
    await priceOracle.updateTwap(crab.address, nftPrice);

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    const treasuryInfo = await voyage.getProtocolFeeParam();
    const treasuryBalanceBefore = await weth.balanceOf(treasuryInfo[0]);
    const vaultBalanceBefore = await weth.balanceOf(vault);

    const updatedNftPrice = toWad(20);
    await priceOracle.updateTwap(crab.address, updatedNftPrice);
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);
    const tresauryBalanceAfter = await weth.balanceOf(treasuryInfo[0]);
    const vaultBalanceAfter = await weth.balanceOf(vault);
    const nper = reserveConfiguration.term / reserveConfiguration.epoch;
    const downpayment = nftPrice.div(nper);
    const totalDebt = nftPrice.sub(downpayment);
    const discountedFloorPrice = await getDiscountedFloorPrice(
      BigNumber.from(updatedNftPrice),
      reserveConfiguration.liquidationBonus
    );

    const effectiveInterestRate = calculateEffectiveInterestRate(
      BigNumber.from(reserveConfiguration.epoch),
      BigNumber.from(nper),
      BigNumber.from(toRay2(reserveConfiguration.baseRate))
    );

    const outstandingSeniorInterest = getOutstandingSeniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );
    const outstandingJuniorInterest = getOutstandingJuniorInterest(
      nftPrice,
      effectiveInterestRate,
      reserveConfiguration.incomeRatio,
      nper
    );

    const outstandingProtocolFee = getOutstandingProtocolFee(
      nftPrice,
      reserveConfiguration.protocolFee,
      nper
    );
    const repayToVault = discountedFloorPrice
      .sub(totalDebt)
      .sub(outstandingSeniorInterest)
      .sub(outstandingJuniorInterest)
      .sub(outstandingProtocolFee);
    expect(seniorTotalAssetBefore).to.eq(seniorTotalAssetAfter);
    expect(juniorTotalAssetBefore).to.eq(juniorTotalAssetAfter);
    expect(tresauryBalanceAfter).to.eq(
      treasuryBalanceBefore.add(outstandingProtocolFee)
    );
    expect(vaultBalanceAfter).to.eq(vaultBalanceBefore.add(repayToVault));
  });

  async function increase(n: number) {
    const days = n * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [days]);
    await ethers.provider.send('evm_mine', []);
  }

  async function getTotalAsset(vToken: Contract) {
    return vToken.totalAssets();
  }

  async function getDiscountedFloorPrice(
    nftPrice: BigNumber,
    liquidationBonus: number
  ) {
    const withBonus = nftPrice.percentMul(liquidationBonus);
    const discount = withBonus.sub(nftPrice);
    return nftPrice.sub(discount);
  }
});

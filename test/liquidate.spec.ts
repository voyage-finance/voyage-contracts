import { expect } from 'chai';
import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { toWad } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

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

    await voyage.setLiquidationBonus(crab.address, 13300);
    await increase(41);
    await priceOracle.updateTwap(crab.address, toWad(10));

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetBefore: ', seniorTotalAssetBefore.toString());
    console.log('juniorTotalAssetBefore: ', juniorTotalAssetBefore.toString());

    await priceOracle.updateTwap(crab.address, toWad(1));
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetAfter: ', seniorTotalAssetAfter.toString());
    console.log('juniorTotalAssetAfter: ', juniorTotalAssetAfter.toString());

    // total debt: 6666666666666666667
    // discounted floor price: 670000000000000000
    // outstanding senior interest: 150000000000000000
    // need to repay from junior tranche 5996666666666666667
    // outstanding junior interest: 150000000000000000
    // writedown senior interest: 150000000000000000
    // weitedown junior interest: 150000000000000000
    // junior tranche subtract 5996666666666666667 + 150000000000000000 == 6146666666666666667
    expect(seniorTotalAssetBefore.toString()).to.eq(
      seniorTotalAssetAfter.add('150000000000000000')
    );

    expect(juniorTotalAssetBefore.toString()).to.eq(
      juniorTotalAssetAfter.add('6146666666666666667')
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

    await voyage.setLiquidationBonus(crab.address, 13300);
    await increase(41);
    await priceOracle.updateTwap(crab.address, toWad(10));

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetBefore: ', seniorTotalAssetBefore.toString());
    console.log('juniorTotalAssetBefore: ', juniorTotalAssetBefore.toString());

    await priceOracle.updateTwap(crab.address, toWad(1));
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetAfter: ', seniorTotalAssetAfter.toString());
    console.log('juniorTotalAssetAfter: ', juniorTotalAssetAfter.toString());

    // junior tranche: 5075000000000000000 (princiapl + first interest repayment from buyNow)
    // total debt: 6666666666666666667
    // discounted floor price: 670000000000000000
    // outstanding senior interest: 150000000000000000
    // need to repay from junior tranche 5000000000000000000
    // outstanding junior interest: 150000000000000000
    // writedown senior interest: 150000000000000000
    // weitedown junior interest: 150000000000000000
    // senior tranche subtract: 150000000000000000 + 6666666666666666667 - 5075000000000000000 - 670000000000000000 == 1071666666666666667
    expect(seniorTotalAssetBefore.toString()).to.eq(
      seniorTotalAssetAfter.add('1071666666666666667')
    );
    expect(juniorTotalAssetAfter.toString()).to.eq('0');
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

    // discountedFloorPrice = 10 - [(bonus - 1)  * 10] / 10
    // discountedFloorPrice = 6.67
    // 6.67 = 10 - [(bonus - 1)  * 10] / 10
    // [(bonus - 1)  * 10] / 10 = 0.33
    // (bonus - 1)  * 10 = 3.3
    // bonus - 1 = 0.33
    // bonus = 1.33
    await voyage.setLiquidationBonus(crab.address, 13300);
    await increase(41);
    await priceOracle.updateTwap(crab.address, toWad(100));

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetBefore: ', seniorTotalAssetBefore.toString());
    console.log('juniorTotalAssetBefore: ', juniorTotalAssetBefore.toString());

    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetAfter: ', seniorTotalAssetAfter.toString());
    console.log('juniorTotalAssetAfter: ', juniorTotalAssetAfter.toString());

    // total debt: 6666666666666666667
    // discounted floor price: 6700000000000000000
    // outstanding senior interest: 150000000000000000
    // outstanding junior interest: 150000000000000000
    // repay senior interest: 33333333333333333
    // writedown senior interest: 116666666666666667
    // weitedown junior interest: 150000000000000000
    expect(seniorTotalAssetBefore.toString()).to.eq(
      seniorTotalAssetAfter.add('116666666666666667')
    );
    expect(juniorTotalAssetBefore.toString()).to.eq(
      juniorTotalAssetAfter.add('150000000000000000')
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

    await voyage.setLiquidationBonus(crab.address, 10000);
    await increase(41);
    await priceOracle.updateTwap(crab.address, toWad(100));

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetBefore: ', seniorTotalAssetBefore.toString());
    console.log('juniorTotalAssetBefore: ', juniorTotalAssetBefore.toString());

    await priceOracle.updateTwap(crab.address, toWad(6.9));
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);
    console.log('seniorTotalAssetAfter: ', seniorTotalAssetAfter.toString());
    console.log('juniorTotalAssetAfter: ', juniorTotalAssetAfter.toString());

    // total debt: 6666666666666666667
    // discounted floor price: 6900000000000000000
    // outstanding senior interest: 150000000000000000
    // outstanding junior interest: 150000000000000000
    // writedown senior interest: 0
    // weitedown junior interest: 66666666666666667
    expect(seniorTotalAssetBefore.toString()).to.eq(seniorTotalAssetAfter);
    expect(juniorTotalAssetBefore.toString()).to.eq(
      juniorTotalAssetAfter.add('66666666666666667')
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
      weth,
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

    await voyage.setLiquidationBonus(crab.address, 10000);
    await increase(41);
    await priceOracle.updateTwap(crab.address, toWad(100));

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    const treasuryInfo = await voyage.getProtocolFeeParam();
    const treasuryBalanceBefore = await weth.balanceOf(treasuryInfo[0]);
    console.log('seniorTotalAssetBefore: ', seniorTotalAssetBefore.toString());
    console.log('juniorTotalAssetBefore: ', juniorTotalAssetBefore.toString());
    console.log('treasuryBalanceBefore: ', treasuryBalanceBefore.toString());

    await priceOracle.updateTwap(crab.address, toWad(7));
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);
    const tresauryBalanceAfter = await weth.balanceOf(treasuryInfo[0]);
    console.log('seniorTotalAssetAfter: ', seniorTotalAssetAfter.toString());
    console.log('juniorTotalAssetAfter: ', juniorTotalAssetAfter.toString());
    console.log('tresauryBalanceAfter: ', tresauryBalanceAfter.toString());

    // total debt: 6666666666666666667
    // discounted floor price: 7000000000000000000
    // outstanding senior interest: 150000000000000000
    // outstanding junior interest: 150000000000000000
    // writedown senior interest: 0
    // weitedown junior interest: 0
    // protocol fee: 7000000000000000000 - 6666666666666666667 - 150000000000000000 - 150000000000000000 == 33333333333333333
    expect(seniorTotalAssetBefore).to.eq(seniorTotalAssetAfter);
    expect(juniorTotalAssetBefore).to.eq(juniorTotalAssetAfter);
    expect(tresauryBalanceAfter).to.eq(
      treasuryBalanceBefore.add('33333333333333333')
    );
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

    await voyage.setLiquidationBonus(crab.address, 10000);
    await increase(41);
    await priceOracle.updateTwap(crab.address, toWad(100));

    // before liquidate
    const seniorTotalAssetBefore = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetBefore = await getTotalAsset(juniorDepositToken);
    const treasuryInfo = await voyage.getProtocolFeeParam();
    const treasuryBalanceBefore = await weth.balanceOf(treasuryInfo[0]);
    const vaultBalanceBefore = await weth.balanceOf(vault);
    console.log('seniorTotalAssetBefore: ', seniorTotalAssetBefore.toString());
    console.log('juniorTotalAssetBefore: ', juniorTotalAssetBefore.toString());
    console.log('treasuryBalanceBefore: ', treasuryBalanceBefore.toString());
    console.log('vaultBalanceBefore: ', vaultBalanceBefore.toString());

    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.liquidate(crab.address, vault, 0);

    // after liquidate
    const seniorTotalAssetAfter = await getTotalAsset(seniorDepositToken);
    const juniorTotalAssetAfter = await getTotalAsset(juniorDepositToken);
    const tresauryBalanceAfter = await weth.balanceOf(treasuryInfo[0]);
    const vaultBalanceAfter = await weth.balanceOf(vault);
    console.log('seniorTotalAssetAfter: ', seniorTotalAssetAfter.toString());
    console.log('juniorTotalAssetAfter: ', juniorTotalAssetAfter.toString());
    console.log('tresauryBalanceAfter: ', tresauryBalanceAfter.toString());
    console.log('vaultBalanceAfter: ', vaultBalanceAfter.toString());

    // total debt: 6666666666666666667
    // discounted floor price: 10000000000000000000
    // outstanding senior interest: 150000000000000000
    // outstanding junior interest: 150000000000000000
    // writedown senior interest: 0
    // weitedown junior interest: 0
    // protocol fee: 133333333333333334
    // transfer back to vault: 10000000000000000000 - 150000000000000000 - 150000000000000000 - 6666666666666666667 - 133333333333333334 == 2899999999999999999
    expect(seniorTotalAssetBefore).to.eq(seniorTotalAssetAfter);
    expect(juniorTotalAssetBefore).to.eq(juniorTotalAssetAfter);
    expect(tresauryBalanceAfter).to.eq(
      treasuryBalanceBefore.add('133333333333333334')
    );
    expect(vaultBalanceAfter).to.eq(
      vaultBalanceBefore.add('2899999999999999999')
    );
  });

  async function increase(n: number) {
    const days = n * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [days]);
    await ethers.provider.send('evm_mine', []);
  }

  async function getTotalAsset(vToken: Contract) {
    return vToken.totalAssets();
  }
});

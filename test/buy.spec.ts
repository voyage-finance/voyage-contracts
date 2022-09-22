import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';
import { ethers } from 'hardhat';
import { getCurrentTimestamp } from '@helpers/chain';

describe('BuyNow', function () {
  it('Buy with wrong vault address should revert', async function () {
    const {
      crab,
      voyage,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    await priceOracle.updateTwap(crab.address, toWad(10));
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        voyage.address,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'Unauthorised');
  });

  it('Buy with wrong currency should revert', async function () {
    const {
      crab,
      voyage,
      priceOracle,
      purchaseDataFromLooksRareWithWrongCurrency,
      marketPlace,
    } = await setupTestSuite();
    await priceOracle.updateTwap(crab.address, toWad(10));
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        voyage.address,
        marketPlace.address,
        purchaseDataFromLooksRareWithWrongCurrency
      )
    ).to.be.revertedWithCustomError(voyage, 'Unauthorised');
  });

  it('Buy with wrong tokenId should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNow(
        crab.address,
        2,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTokenid');
  });

  it('Buy with insufficient senior liquidity should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientCash');
  });

  it('Buy with invalid floor price should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      priceOracle,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    await priceOracle.updateTwap(crab.address, 0);
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidFloorPrice');
  });

  it('Buy with 0 max twap staleness should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      priceOracle,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    await voyage.setMaxTwapStaleness(crab.address, 0);
    await priceOracle.updateTwap(crab.address, toWad(10));
    const timestampBefore = await getCurrentTimestamp();
    await ethers.provider.send('evm_mine', [timestampBefore + 100]);

    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'BuyNowStaleTwap');
  });

  it('Buy with just staled floor price should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      priceOracle,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    await voyage.setMaxTwapStaleness(crab.address, 100);
    await priceOracle.updateTwap(crab.address, toWad(10));
    const timestampBefore = await getCurrentTimestamp();
    await ethers.provider.send('evm_mine', [timestampBefore + 100]);

    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'BuyNowStaleTwap');
  });

  it('Buy with outdated floor price should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      priceOracle,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    await voyage.setMaxTwapStaleness(crab.address, 100);
    await priceOracle.updateTwap(crab.address, toWad(10));
    const timestampBefore = await getCurrentTimestamp();
    await ethers.provider.send('evm_mine', [timestampBefore + 1000]);

    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'BuyNowStaleTwap');
  });

  it('Buy with insufficient junior liquidity should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      marketPlace,
      purchaseDataFromLooksRare,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidJuniorTrancheBalance');

    await voyage.deposit(crab.address, 0, toWad(1));
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientJuniorLiquidity');
  });

  it('Buy with invalid principal should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      marketPlace,
      purchaseDataFromLooksRare,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(0.000001));
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'ExceedsFloorPrice');
  });

  it('Buy with sufficient credit limit should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRare,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      reserveConfiguration,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);

    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );

    // check pool data
    const creditLine = await voyage.getCreditLineData(vault, crab.address);
    console.log('total debt: ', creditLine.totalDebt.toString());
    expect(creditLine.loanList.head).to.eq(0);
    expect(creditLine.loanList.tail).to.eq(1);

    const { term, epoch } = reserveConfiguration;
    const nper = ethers.BigNumber.from(term).div(epoch);

    // check loan detail
    const loanDetail = await voyage.getLoanDetail(vault, crab.address, 0);
    const principalPmt = loanDetail.interest.div(nper);
    const interestPmt = loanDetail.principal.div(nper);
    const firstPmt = principalPmt.add(interestPmt);
    const totalDebtExpected = firstPmt.add(creditLine.totalDebt);
    expect(totalDebtExpected).to.eq(
      loanDetail.principal.add(loanDetail.interest)
    );
    expect(
      loanDetail.totalPrincipalPaid.add(loanDetail.totalInterestPaid)
    ).to.eq(firstPmt);
  });

  it('Buy with sufficient credit limit with WETH from looks should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      reserveConfiguration,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH
    );
    console.log(
      'purchaseDataFromLooksRareWithWETH: ',
      purchaseDataFromLooksRareWithWETH
    );

    // check pool data
    const creditLine = await voyage.getCreditLineData(vault, crab.address);
    console.log('total debt: ', creditLine.totalDebt.toString());
    expect(creditLine.loanList.head).to.eq(0);
    expect(creditLine.loanList.tail).to.eq(1);

    const { term, epoch } = reserveConfiguration;
    const nper = ethers.BigNumber.from(term).div(epoch);

    // check loan detail
    const loanDetail = await voyage.getLoanDetail(vault, crab.address, 0);
    const principalPmt = loanDetail.interest.div(nper);
    const interestPmt = loanDetail.principal.div(nper);
    const firstPmt = principalPmt.add(interestPmt);
    const totalDebtExpected = firstPmt.add(creditLine.totalDebt);
    expect(totalDebtExpected).to.eq(
      loanDetail.principal.add(loanDetail.interest)
    );
    expect(
      loanDetail.totalPrincipalPaid.add(loanDetail.totalInterestPaid)
    ).to.eq(firstPmt);
  });

  it('Buy with sufficient credit limit from OS should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromOpensea,
      seaport,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    const param = await voyage.previewBuyNowParams(
      crab.address,
      vault,
      10000000000
    );
    console.log('purchaseDataFromOpensea: ', purchaseDataFromOpensea);
    console.log(param);
    await voyage.buyNow(
      crab.address,
      6532,
      vault,
      seaport.address,
      purchaseDataFromOpensea
    );
  });
});

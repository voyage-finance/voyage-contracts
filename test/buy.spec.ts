import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';

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

  it('Buy with insufficient liquidity should revert', async function () {
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
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientLiquidity');
  });

  it('Buy with invalid floor price should revert', async function () {
    const { crab, owner, voyage, purchaseDataFromLooksRare, marketPlace } =
      await setupTestSuite();
    const vault = await voyage.getVault(owner);
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
    await priceOracle.updateTwap(crab.address, toWad(1));
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidPrincipal');
  });

  it('Buy with sufficient credit limit should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
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

    // check loan detail
    const loanDetail = await voyage.getLoanDetail(vault, crab.address, 0);
    const firstPmt = loanDetail.principal.add(loanDetail.interest).div(3);
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
    const param = await voyage.previewBuyNowParams(crab.address);
    console.log(param);
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      seaport.address,
      purchaseDataFromOpensea
    );
  });
});

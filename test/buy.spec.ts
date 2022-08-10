import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';

describe('BuyNow', function () {
  it('Buy with wrong vault address should revert', async function () {
    const { crab, voyage, priceOracle, purchaseData, marketPlace } =
      await setupTestSuite();
    await priceOracle.updateTwap(crab.address, toWad(10));
    await expect(
      voyage.buyNow(
        crab.address,
        1,
        voyage.address,
        marketPlace.address,
        purchaseData
      )
    ).to.be.revertedWith('Unauthorised()');
  });

  it('Buy with insufficient liquidity should revert', async function () {
    const { crab, owner, voyage, priceOracle, purchaseData, marketPlace } =
      await setupTestSuite();
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNow(crab.address, 1, vault, marketPlace.address, purchaseData)
    ).to.be.revertedWith('InsufficientLiquidity()');
  });

  it('Buy with invalid floor price should revert', async function () {
    const { crab, owner, voyage, purchaseData, marketPlace } =
      await setupTestSuite();
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNow(crab.address, 1, vault, marketPlace.address, purchaseData)
    ).to.be.revertedWith('InvalidFloorPrice()');
  });

  it('Buy with insufficient credit limit should revert', async function () {
    const { crab, owner, voyage, priceOracle, marketPlace, purchaseData } =
      await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(1));
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNow(crab.address, 1, vault, marketPlace.address, purchaseData)
    ).to.be.revertedWith('InsufficientCreditLimit()');
  });

  it('Buy with sufficient credit limit should pass', async function () {
    const { crab, owner, voyage, priceOracle, purchaseData, marketPlace } =
      await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseData
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
});
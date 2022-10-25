import { expect } from 'chai';
import {
  setupTestSuite,
  setupTestTwapToleranceMock,
} from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';
import { ethers } from 'hardhat';
import { getCurrentTimestamp } from '@helpers/chain';

describe('BuyNowV2', function () {
  it('Buy with wrong vault address should revert', async function () {
    const { crab, voyage, purchaseDataFromLooksRare, marketPlace, weth } =
      await setupTestSuite();
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        voyage.address,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'Unauthorised');
  });

  it('Buy with wrong currency should revert', async function () {
    const {
      crab,
      voyage,
      purchaseDataFromLooksRareWithWrongCurrency,
      marketPlace,
      weth,
    } = await setupTestSuite();
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        voyage.address,
        marketPlace.address,
        purchaseDataFromLooksRareWithWrongCurrency,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'Unauthorised');
  });

  it('Buy with wrong tokenId should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
    } = await setupTestSuite();
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNowV2(
        crab.address,
        2,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTokenid');
  });

  it('Buy with wrong collection address should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
    } = await setupTestSuite();
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await expect(
      voyage.buyNowV2(
        marketPlace.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidCollection');
  });

  it('Buy with insufficient senior liquidity should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
    } = await setupTestSuite();
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
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
      weth,
    } = await setupTestSuite();
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000),
      0
    );
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
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
      weth,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const vault = await voyage.getVault(owner);
    await voyage.setMaxTwapStaleness(crab.address, 0);
    console.log(
      'getMaxTwapStaleness',
      await voyage.getMaxTwapStaleness(crab.address)
    );
    const timestampBefore = await getCurrentTimestamp();
    const currentTime = Math.floor(Date.now() / 1000);
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      currentTime - 1000
    );
    await ethers.provider.send('evm_mine', [currentTime + 1000]);

    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTwapMessage');
  });

  it('Buy with insufficient junior liquidity should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      marketPlace,
      purchaseDataFromLooksRare,
      weth,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    await voyage.deposit(crab.address, 1, depositAmount);
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidJuniorTrancheBalance');

    await voyage.deposit(crab.address, 0, toWad(1));
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientJuniorLiquidity');
  });

  it('Buy with invalid principal should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      marketPlace,
      purchaseDataFromLooksRare,
      weth,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000),
      0.000001
    );
    const vault = await voyage.getVault(owner);
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'ExceedsFloorPrice');
  });

  it('Buy with sufficient credit limit should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      reserveConfiguration,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);

    await voyage.buyNowV2(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare,
      message
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
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      reserveConfiguration,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);
    await voyage.buyNowV2(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH,
      message
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

  it('Buy with sufficient credit limit with insufficient ETH+WETH from looks should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);

    // check vault balance
    const ethBalance = await ethers.provider.getBalance(vault);
    const wethBalance = await weth.balanceOf(vault);
    console.log('eth balance: ', ethBalance.toString());
    console.log('weth balance: ', wethBalance.toString());

    // transfer eth out
    await voyage.transferETH(vault, owner, ethBalance.sub(toWad(1)));
    await voyage.transferCurrency(
      vault,
      weth.address,
      owner,
      wethBalance.sub(toWad(1))
    );
    const ethBalanceAfter = await ethers.provider.getBalance(vault);
    const wethBalanceAfter = await weth.balanceOf(vault);
    console.log('eth balance after: ', ethBalanceAfter.toString());
    console.log('weth balance after: ', wethBalanceAfter.toString());

    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRareWithWETH,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientVaultETHBalance');
  });

  it('Buy with sufficient credit limit with 0 ETH + WETH from looks should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);

    // check vault balance
    const ethBalance = await ethers.provider.getBalance(vault);
    const wethBalance = await weth.balanceOf(vault);
    console.log('eth balance: ', ethBalance.toString());
    console.log('weth balance: ', wethBalance.toString());

    // transfer eth out
    await voyage.transferETH(vault, owner, ethBalance);
    await voyage.transferCurrency(vault, weth.address, owner, wethBalance);
    const ethBalanceAfter = await ethers.provider.getBalance(vault);
    const wethBalanceAfter = await weth.balanceOf(vault);
    console.log('eth balance after: ', ethBalanceAfter.toString());
    console.log('weth balance after: ', wethBalanceAfter.toString());

    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRareWithWETH,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientVaultETHBalance');
  });

  it('Buy with sufficient credit limit with sufficient ETH from looks should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);

    // check vault balance
    const ethBalance = await ethers.provider.getBalance(vault);
    const wethBalance = await weth.balanceOf(vault);
    console.log('eth balance: ', ethBalance.toString());
    console.log('weth balance: ', wethBalance.toString());

    // await voyage.transferETH(vault, owner, ethBalance);
    await voyage.transferCurrency(vault, weth.address, owner, wethBalance);
    const ethBalanceAfter = await ethers.provider.getBalance(vault);
    const wethBalanceAfter = await weth.balanceOf(vault);
    console.log('eth balance after: ', ethBalanceAfter.toString());
    console.log('weth balance after: ', wethBalanceAfter.toString());
    voyage.buyNowV2(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH,
      message
    );

    // check pool data
    const creditLine = await voyage.getCreditLineData(vault, crab.address);
    console.log('total debt: ', creditLine.totalDebt.toString());
    expect(creditLine.loanList.head).to.eq(0);
    expect(creditLine.loanList.tail).to.eq(1);
  });

  it('Buy with sufficient credit limit with sufficient WETH from looks should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);

    // check vault balance
    const ethBalance = await ethers.provider.getBalance(vault);
    const wethBalance = await weth.balanceOf(vault);
    console.log('eth balance: ', ethBalance.toString());
    console.log('weth balance: ', wethBalance.toString());

    // transfer eth out
    await voyage.transferETH(vault, owner, ethBalance);
    // await voyage.transferCurrency(vault, weth.address, owner, wethBalance);
    const ethBalanceAfter = await ethers.provider.getBalance(vault);
    const wethBalanceAfter = await weth.balanceOf(vault);
    console.log('eth balance after: ', ethBalanceAfter.toString());
    console.log('weth balance after: ', wethBalanceAfter.toString());

    voyage.buyNowV2(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH,
      message
    );

    // check pool data
    const creditLine = await voyage.getCreditLineData(vault, crab.address);
    console.log('total debt: ', creditLine.totalDebt.toString());
    expect(creditLine.loanList.head).to.eq(0);
    expect(creditLine.loanList.tail).to.eq(1);
  });

  it('Buy with sufficient credit limit with sufficient ETH+WETH from looks should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);

    // check vault balance
    const ethBalance = await ethers.provider.getBalance(vault);
    const wethBalance = await weth.balanceOf(vault);
    console.log('eth balance: ', ethBalance.toString());
    console.log('weth balance: ', wethBalance.toString());

    // transfer eth out
    await voyage.transferETH(vault, owner, ethBalance.sub(toWad(5)));
    await voyage.transferCurrency(
      vault,
      weth.address,
      owner,
      wethBalance.sub(toWad(5))
    );
    const ethBalanceAfter = await ethers.provider.getBalance(vault);
    const wethBalanceAfter = await weth.balanceOf(vault);
    console.log('eth balance after: ', ethBalanceAfter.toString());
    console.log('weth balance after: ', wethBalanceAfter.toString());

    voyage.buyNowV2(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH,
      message
    );

    // check pool data
    const creditLine = await voyage.getCreditLineData(vault, crab.address);
    console.log('total debt: ', creditLine.totalDebt.toString());
    expect(creditLine.loanList.head).to.eq(0);
    expect(creditLine.loanList.tail).to.eq(1);
  });

  it('Buy with sufficient credit limit from OS should pass', async function () {
    const { crab, owner, voyage, purchaseDataFromOpensea, seaport, weth } =
      await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const message = await setupTestTwapToleranceMock(
      crab.address,
      voyage,
      weth.address,
      Math.floor(Date.now() / 1000)
    );
    const vault = await voyage.getVault(owner);
    const param = await voyage.previewBuyNowParams(
      crab.address,
      vault,
      10000000000
    );
    console.log('purchaseDataFromOpensea: ', purchaseDataFromOpensea);
    console.log(param);
    await voyage.buyNowV2(
      crab.address,
      6532,
      vault,
      seaport.address,
      purchaseDataFromOpensea,
      message
    );
  });
});

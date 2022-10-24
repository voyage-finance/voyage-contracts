import { expect } from 'chai';
import {
  setupTestSuite,
  setupTestSuiteSecondToken,
} from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';
import { ethers } from 'hardhat';
import { getCurrentTimestamp } from '@helpers/chain';
import { Contract } from 'ethers';

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

  it('Buy with wrong collection address should revert', async function () {
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
        marketPlace.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidCollection');
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
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
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

  it('Buy with sufficient credit limit with insufficient ETH+WETH from looks should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
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
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRareWithWETH
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientVaultETHBalance');
  });

  it('Buy with sufficient credit limit with 0 ETH + WETH from looks should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
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
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRareWithWETH
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientVaultETHBalance');
  });

  it('Buy with sufficient credit limit with sufficient ETH from looks should pass', async function () {
    const {
      crab,
      owner,
      voyage,
      priceOracle,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
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
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH
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
      priceOracle,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
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

    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH
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
      priceOracle,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
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

    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRareWithWETH
    );

    // check pool data
    const creditLine = await voyage.getCreditLineData(vault, crab.address);
    console.log('total debt: ', creditLine.totalDebt.toString());
    expect(creditLine.loanList.head).to.eq(0);
    expect(creditLine.loanList.tail).to.eq(1);
    console.log(
      'eth balance after2: ',
      (await ethers.provider.getBalance(vault)).toString()
    );
    console.log(
      'weth balance after2: ',
      (await weth.balanceOf(vault)).toString()
    );
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

  // >>>>>>>>>>>> BuyNow two person scenario <<<<<<<<<<<<<<<<

  async function depositJuniorSenior(
    voyage: Contract,
    crab: Contract,
    juniorAmount: number,
    seniorAmount: number,
    weth: Contract
  ) {
    // deposit junior/senior
    await voyage.deposit(crab.address, 0, toWad(juniorAmount));
    await voyage.deposit(crab.address, 1, toWad(seniorAmount));

    const tokens = await voyage.getDepositTokens(crab.address);
    const afterJuniorBalance = await weth.balanceOf(tokens.junior);
    const afterSeniorBalance = await weth.balanceOf(tokens.senior);
    console.log('JuniorBalance initially: ', afterJuniorBalance.toString());
    console.log('SeniorBalance: initially', afterSeniorBalance.toString());
  }

  async function depositEthWeth(
    vault: string,
    weth: Contract,
    owner: string,
    voyage: Contract,
    ethAmount: number,
    wethAmount: number
  ) {
    // transfer eth + weth
    const ethBalance = await ethers.provider.getBalance(vault);
    const wethBalance = await weth.balanceOf(vault);

    await voyage.transferETH(vault, owner, ethBalance.sub(toWad(ethAmount)));
    await voyage.transferCurrency(
      vault,
      weth.address,
      owner,
      wethBalance.sub(toWad(wethAmount))
    );
    const ethBalanceAfter = await ethers.provider.getBalance(vault);
    const wethBalanceAfter = await weth.balanceOf(vault);
    console.log('eth balance: ', ethBalanceAfter.toString());
    console.log('weth balance: ', wethBalanceAfter.toString());
  }

  it(
    'sufficient junior/senior reserve, sufficient eth+weth deposit ⇒ pass' +
      'sufficient junior/senior reserve, sufficient eth+weth deposit ⇒ pass',
    async function () {
      const {
        crab,
        owner,
        voyage,
        priceOracle,
        marketPlace,
        purchaseDataFromLooksRare,
        weth,
      } = await setupTestSuite();
      // 1.0 setup
      const secondTokenSetup = await setupTestSuiteSecondToken();
      const purchaseDataFromLooksRareSecondToken =
        secondTokenSetup.purchaseDataFromLooksRare;
      const vault = await voyage.getVault(owner);
      await depositJuniorSenior(voyage, crab, 50, 120, weth);
      await depositEthWeth(vault, weth, owner, voyage, 50, 50);
      await priceOracle.updateTwap(crab.address, toWad(10));
      // 1.1 first buy
      await voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      );
      console.log('First buyNow was successful!');
      // 2.0 check balances after the first buy
      console.log(
        'eth balance after: ',
        (await ethers.provider.getBalance(vault)).toString()
      );
      console.log(
        'weth balance after: ',
        (await weth.balanceOf(vault)).toString()
      );
      await voyage.buyNow(
        crab.address,
        2,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRareSecondToken
      );
    }
  );

  it(
    'sufficient junior/senior reserve, sufficient eth+weth deposit ⇒ pass' +
      'insufficient junior/senior reserve, sufficient eth+weth deposit ⇒ revert',
    async function () {
      const {
        crab,
        owner,
        voyage,
        priceOracle,
        marketPlace,
        purchaseDataFromLooksRare,
        weth,
      } = await setupTestSuite();
      // 1.0 setup
      const secondTokenSetup = await setupTestSuiteSecondToken();
      const purchaseDataFromLooksRareSecondToken =
        secondTokenSetup.purchaseDataFromLooksRare;
      const vault = await voyage.getVault(owner);
      await depositJuniorSenior(voyage, crab, 20, 10, weth);
      await depositEthWeth(vault, weth, owner, voyage, 50, 50);
      await priceOracle.updateTwap(crab.address, toWad(10));
      // 1.1 first buy
      await voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      );
      console.log('First buyNow was successful!');

      // 2.0 check balances after the first buy
      const tokens = await voyage.getDepositTokens(crab.address);
      const afterJuniorBalance = await weth.balanceOf(tokens.junior);
      const afterSeniorBalance = await weth.balanceOf(tokens.senior);
      console.log('afterJuniorBalance: ', afterJuniorBalance.toString());
      console.log('afterSeniorBalance: ', afterSeniorBalance.toString());
      // 2.1 senior balance must be insufficient
      expect(afterSeniorBalance.lte(toWad(10))).to.eq(true);
      await expect(
        voyage.buyNow(
          crab.address,
          2,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRareSecondToken
        )
      ).to.be.revertedWithCustomError(voyage, 'InsufficientLiquidity');
    }
  );

  it(
    'sufficient junior/senior reserve, sufficient eth+weth deposit ⇒ pass' +
      'sufficient junior/senior reserve, insufficient eth+weth deposit ⇒ revert',
    async function () {
      const {
        crab,
        owner,
        voyage,
        priceOracle,
        marketPlace,
        purchaseDataFromLooksRare,
        weth,
      } = await setupTestSuite();
      // 1.0 setup
      const secondTokenSetup = await setupTestSuiteSecondToken();
      const purchaseDataFromLooksRareSecondToken =
        secondTokenSetup.purchaseDataFromLooksRare;
      const vault = await voyage.getVault(owner);
      await depositJuniorSenior(voyage, crab, 50, 120, weth);
      await depositEthWeth(vault, weth, owner, voyage, 4, 0);
      await priceOracle.updateTwap(crab.address, toWad(10));
      // 1.1 first buy
      await voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      );
      console.log('First buyNow was successful!');

      // 2.0 check balances after the first buy
      const afterWethBalance = await weth.balanceOf(vault);
      console.log(
        'eth balance after: ',
        (await ethers.provider.getBalance(vault)).toString()
      );
      console.log('weth balance after: ', afterWethBalance.toString());
      // 2.1 weth balance must be insufficient
      expect(afterWethBalance.lte(toWad(4))).to.eq(true);
      await expect(
        voyage.buyNow(
          crab.address,
          2,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRareSecondToken
        )
      ).to.be.revertedWithCustomError(voyage, 'InsufficientVaultETHBalance');
    }
  );

  it(
    'insufficient junior/senior reserve, sufficient eth+weth deposit ⇒ revert' +
      'sufficient junior/senior reserve, sufficient eth+weth deposit ⇒ pass',
    async function () {
      const {
        crab,
        owner,
        voyage,
        priceOracle,
        marketPlace,
        purchaseDataFromLooksRare,
        weth,
      } = await setupTestSuite();
      // 1.0 setup
      const secondTokenSetup = await setupTestSuiteSecondToken();
      const purchaseDataFromLooksRareSecondToken =
        secondTokenSetup.purchaseDataFromLooksRare;
      const vault = await voyage.getVault(owner);
      await depositJuniorSenior(voyage, crab, 1, 1, weth);
      // await voyage.deposit(crab.address, 0, toWad(50));
      await depositEthWeth(vault, weth, owner, voyage, 20, 20);
      await priceOracle.updateTwap(crab.address, toWad(10));
      // 1.1 first buy with low junior balance
      await expect(
        voyage.buyNow(
          crab.address,
          1,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRare
        )
      ).to.be.revertedWithCustomError(voyage, 'InsufficientJuniorLiquidity');
      // 1.2 first buy with low senior balance
      await depositJuniorSenior(voyage, crab, 50, 1, weth);
      await expect(
        voyage.buyNow(
          crab.address,
          1,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRare
        )
      ).to.be.revertedWithCustomError(voyage, 'InsufficientLiquidity');
      console.log('First buyNow was reverted!');

      // 2.0 sufficient junior/senior balances
      await depositJuniorSenior(voyage, crab, 50, 120, weth);
      const tokens = await voyage.getDepositTokens(crab.address);
      const afterJuniorBalance = await weth.balanceOf(tokens.junior);
      const afterSeniorBalance = await weth.balanceOf(tokens.senior);
      console.log('afterJuniorBalance: ', afterJuniorBalance.toString());
      console.log('afterSeniorBalance: ', afterSeniorBalance.toString());
      // 2.1 second buy
      await voyage.buyNow(
        crab.address,
        2,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRareSecondToken
      );
    }
  );
});

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';

describe('Repay', function () {
  function showLoan(loan: any) {
    console.log('principal: ', loan.principal.toString());
    console.log('totalPrincipalPaid', loan.totalPrincipalPaid.toString());
    console.log('totalInterestPaid', loan.totalInterestPaid.toString());
    console.log('pmt.principal: ', loan.pmt.principal.toString());
    console.log('pmt.interest: ', loan.pmt.interest.toString());
    console.log('pmt: ', loan.pmt.pmt.toString());
  }

  it('Repay should return correct value', async function () {
    const {
      owner,
      juniorDepositToken,
      seniorDepositToken,
      weth,
      crab,
      voyage,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
      reserveConfiguration,
    } = await setupTestSuite();

    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.deposit(crab.address, 0, depositAmount);
    await voyage.deposit(crab.address, 1, depositAmount);
    const seniorLiquidity = await weth.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await weth.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.setMaxTwapStaleness(crab.address, '100000000000');
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const creditLineData = await voyage.getCreditLineData(vault, crab.address);

    console.log('total debt: ', creditLineData.totalDebt.toString());
    console.log(
      'draw down list: [',
      creditLineData.loanList.head.toString(),
      ',',
      creditLineData.loanList.tail.toString(),
      ']'
    );

    await expect(
      voyage.buyNow(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare
      )
    ).to.be.revertedWithCustomError(voyage, 'InsufficientCreditLimit');

    const loanDetail00 = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down 00: ');
    showLoan(loanDetail00);

    const loanDetail10 = await voyage.getLoanDetail(vault, crab.address, 1);
    console.log('draw down 10: ');
    showLoan(loanDetail10);

    const { term, epoch } = reserveConfiguration;
    const nper = ethers.BigNumber.from(term).div(epoch);

    // repay draw down 0
    await voyage.repay(crab.address, 0, vault);
    const loanDetail01 = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down 01: ');
    showLoan(loanDetail01);
    expect(loanDetail01.totalPrincipalPaid.toString()).to.equal(
      loanDetail01.principal.div(nper).mul(2)
    );
    expect(loanDetail01.totalInterestPaid.toString()).to.equal(
      loanDetail01.interest.div(nper).mul(2)
    );

    // repay draw down 0 again
    await voyage.repay(crab.address, 0, vault);
    const loanDetail02 = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down 02: ');
    showLoan(loanDetail02);
    expect(loanDetail02.totalPrincipalPaid).to.equal(ethers.constants.Zero);
    expect(loanDetail02.totalPrincipalPaid).to.equal(ethers.constants.Zero);

    // withdraw nft
    await voyage.withdrawNFT(vault, crab.address, '1');
    await expect(await crab.ownerOf(1)).to.equal(owner);
  });
});

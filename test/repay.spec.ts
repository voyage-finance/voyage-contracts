import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';

const max = 1000;
const requirement = 0.1 * 1e4;
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
      tus,
      crab,
      voyage,
      priceOracle,
      purchaseData,
    } = await setupTestSuite();

    const vault = await voyage.getVault(owner);

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMarginParams(crab.address, 0, max, requirement);
    await voyage.deposit(crab.address, 0, depositAmount);
    await voyage.deposit(crab.address, 1, depositAmount);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(crab.address, '1', vault, purchaseData);

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

    await voyage.buyNow(
      crab.address,
      '10000000000000000000',
      vault,
      purchaseData
    );

    const vaultData2 = await voyage.getCreditLineData(vault, crab.address);

    console.log('total debt: ', vaultData2.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData2.loanList.head.toString(),
      ',',
      vaultData2.loanList.tail.toString(),
      ']'
    );

    const loanDetail = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down 0: ');
    showLoan(loanDetail);

    const loanDetail1 = await voyage.getLoanDetail(vault, crab.address, 1);
    console.log('draw down 1: ');
    showLoan(loanDetail1);

    // repay the second draw down
    await voyage.repay(crab.address, 0, vault);
    const loanDetailAfter = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down after 0: ');
    showLoan(loanDetailAfter);
  });
});

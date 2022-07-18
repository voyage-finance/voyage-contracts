import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

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
    const { owner, juniorDepositToken, seniorDepositToken, tus, voyage } =
      await setupTestSuite();

    const vault = await voyage.getVault(owner);

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMarginParams(tus.address, 0, max, requirement);
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());

    await voyage.depositMargin(vault, tus.address, '100000000000000000000');
    await voyage.borrow(tus.address, '10000000000000000000', vault);

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const creditLineData = await voyage.getCreditLineData(vault, tus.address);

    console.log('total debt: ', creditLineData.totalDebt.toString());
    console.log(
      'draw down list: [',
      creditLineData.loanList.head.toString(),
      ',',
      creditLineData.loanList.tail.toString(),
      ']'
    );

    const loanDetail = await voyage.getLoanDetail(vault, tus.address, 0);
    console.log('draw down 0: ');
    showLoan(loanDetail);

    await voyage.borrow(tus.address, '10000000000000000000', vault);

    const vaultData2 = await voyage.getCreditLineData(vault, tus.address);

    console.log('total debt: ', vaultData2.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData2.loanList.head.toString(),
      ',',
      vaultData2.loanList.tail.toString(),
      ']'
    );
    const loanDetail2 = await voyage.getLoanDetail(vault, tus.address, 1);
    console.log('draw down 1: ');
    showLoan(loanDetail2);

    // repay the first draw down
    await voyage.repay(tus.address, 0, vault);
    const loanDetail3 = await voyage.getLoanDetail(vault, tus.address, 0);
    console.log('draw down 0: ');
    showLoan(loanDetail3);

    await voyage.repay(tus.address, 0, vault);
    const loanDetail4 = await voyage.getLoanDetail(vault, tus.address, 0);
    console.log('draw down 0: ');
    showLoan(loanDetail4);

    await voyage.repay(tus.address, 0, vault);
    const loanDetail5 = await voyage.getLoanDetail(vault, tus.address, 0);
    console.log('draw down 0: ');
    showLoan(loanDetail5);
  });

  it('Repay a non-debt should revert', async function () {
    const { juniorDepositToken, seniorDepositToken, tus, voyage, owner } =
      await setupTestSuite();
    const vault = await voyage.getVault(owner);

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMarginParams(tus.address, 0, max, requirement);
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyage.depositMargin(vault, tus.address, '100000000000000000000');
    await voyage.borrow(tus.address, '10000000000000000000', vault);

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const loanDetail = await voyage.getLoanDetail(vault, tus.address, 0);

    await voyage.borrow(tus.address, '10000000000000000000', vault);

    // repay the first draw down
    await voyage.repay(tus.address, 0, vault);
    await voyage.repay(tus.address, 0, vault);
    await voyage.repay(tus.address, 0, vault);
    await expect(voyage.repay(tus.address, 0, vault)).to.be.revertedWith(
      'InvalidDebt()'
    );
  });
});

import { ethers, getNamedAccounts } from 'hardhat';
import { setupDebtTestSuite } from '../helpers/debt';

describe('Repayment', function () {
  it('Repay should return correct value', async function () {
    const {
      juniorDepositToken,
      seniorDepositToken,
      stableDebtToken,
      tus,
      vm,
      lm,
      voyager,
    } = await setupDebtTestSuite();

    const { owner } = await getNamedAccounts();

    // 100
    const depositAmount = '100000000000000000000';
    await lm.activeReserve(tus.address);
    await vm.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount);
    await voyager.deposit(tus.address, 1, depositAmount);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);

    // get security deposit escrow address
    const Vault = await ethers.getContractFactory('Vault');
    const escrowAddress = await Vault.attach(
      vaultAddr
    ).getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(escrowAddress, '1000000000000000000000');

    await voyager.depositSecurity(owner, tus.address, '100000000000000000000');
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0);

    const StableDebtToken = await ethers.getContractFactory('StableDebtToken');
    const debtToken = await StableDebtToken.attach(stableDebtToken.address);
    const debtBalance = await debtToken.balanceOf(vaultAddr);
    console.log('debt balance: ', debtBalance.toString());

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const debtBalanceAfterSevenDays = await debtToken.balanceOf(vaultAddr);
    console.log(
      'debt balance after 7 days: ',
      debtBalanceAfterSevenDays.toString()
    );

    const drawDownNumber = (await debtToken.drawDoneNumber(vaultAddr)) - 1;
    console.log('draw down number: ', drawDownNumber.toString());

    const drawDown = await debtToken.drawDown(
      vaultAddr,
      drawDownNumber.toString()
    );
    console.log('debt amount: ', drawDown.amount.toString());
    await voyager.repay(
      tus.address,
      drawDownNumber,
      '1000000000000000000',
      vaultAddr
    );

    await voyager.repay(
      tus.address,
      drawDownNumber,
      '1000000000000000000',
      vaultAddr
    );

    const drawDownAfter = await debtToken.drawDown(
      vaultAddr,
      drawDownNumber.toString()
    );
    console.log('debt amount after: ', drawDownAfter.amount.toString());

    const repaymentOverall = await debtToken.repaymentOverall(
      vaultAddr,
      drawDownNumber.toString()
    );
    console.log('current total paid: ', repaymentOverall.totalPaid.toString());
    console.log('current tenure: ', repaymentOverall.numPayments.toString());

    const repaymentRecord = await debtToken.repaymentHistory(
      vaultAddr,
      drawDownNumber.toString(),
      repaymentOverall.numPayments - 1
    );
    console.log('repayment record: ', repaymentRecord.toString());
  });
});

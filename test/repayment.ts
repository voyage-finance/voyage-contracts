import { ethers, getNamedAccounts } from 'hardhat';
import { setupDebtTestSuite } from '../helpers/debt';

describe('Repayment', function () {
  it('Repay should return correct value', async function () {
    const {
      juniorDepositToken,
      seniorDepositToken,
      tus,
      vm,
      lm,
      voyager,
      voyageProtocolDataProvider,
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

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const vaultData = await voyageProtocolDataProvider.getVaultData(
      owner,
      tus.address,
      owner
    );

    console.log('total debt: ', vaultData.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData.drawDownList.head.toString(),
      ',',
      vaultData.drawDownList.tail.toString(),
      ']'
    );

    const drawDownDetail = await voyageProtocolDataProvider.getDrawDownDetail(
      owner,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    console.log(
      'drawDownDetail.nextPaymentDue: ',
      drawDownDetail.nextPaymentDue.toString()
    );
    console.log(
      'drawDownDetail.principal: ',
      drawDownDetail.pmt.principal.toString()
    );
    console.log(
      'drawDownDetail.interest: ',
      drawDownDetail.pmt.interest.toString()
    );
    console.log('drawDownDetail.pmt: ', drawDownDetail.pmt.pmt.toString());

    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0);

    const vaultData2 = await voyageProtocolDataProvider.getVaultData(
      owner,
      tus.address,
      owner
    );

    console.log('total debt: ', vaultData2.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData2.drawDownList.head.toString(),
      ',',
      vaultData2.drawDownList.tail.toString(),
      ']'
    );
    const drawDownDetail2 = await voyageProtocolDataProvider.getDrawDownDetail(
      owner,
      tus.address,
      1
    );
    console.log('draw down 1: ');
    console.log(
      'drawDownDetail.nextPaymentDue: ',
      drawDownDetail2.nextPaymentDue.toString()
    );
    console.log(
      'drawDownDetail.principal: ',
      drawDownDetail2.pmt.principal.toString()
    );
    console.log(
      'drawDownDetail.interest: ',
      drawDownDetail2.pmt.interest.toString()
    );
    console.log('drawDownDetail.pmt: ', drawDownDetail2.pmt.pmt.toString());
  });
});

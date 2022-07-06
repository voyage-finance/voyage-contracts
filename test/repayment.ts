import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Repayment', function () {
  function showDrawDown(drawDown: any) {
    console.log('principal: ', drawDown.principal.toString());
    console.log('totalPrincipalPaid', drawDown.totalPrincipalPaid.toString());
    console.log('totalInterestPaid', drawDown.totalInterestPaid.toString());
    console.log('pmt.principal: ', drawDown.pmt.principal.toString());
    console.log('pmt.interest: ', drawDown.pmt.interest.toString());
    console.log('pmt: ', drawDown.pmt.pmt.toString());
  }

  it('Repay should return correct value', async function () {
    const {
      owner,
      juniorDepositToken,
      seniorDepositToken,
      vault,
      tus,
      voyage,
    } = await setupTestSuite();

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMaxMargin(tus.address, '1000000000000000000000');
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyage.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyage.borrow(tus.address, '10000000000000000000', vault.address);

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const vaultData = await voyage.getVaultData(vault.address, tus.address);

    console.log('total debt: ', vaultData.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData.drawDownList.head.toString(),
      ',',
      vaultData.drawDownList.tail.toString(),
      ']'
    );

    const drawDownDetail = await voyage.getDrawDownDetail(
      vault.address,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail);

    await voyage.borrow(tus.address, '10000000000000000000', vault.address);

    const vaultData2 = await voyage.getVaultData(vault.address, tus.address);

    console.log('total debt: ', vaultData2.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData2.drawDownList.head.toString(),
      ',',
      vaultData2.drawDownList.tail.toString(),
      ']'
    );
    const drawDownDetail2 = await voyage.getDrawDownDetail(
      vault.address,
      tus.address,
      1
    );
    console.log('draw down 1: ');
    showDrawDown(drawDownDetail2);

    // repay the first draw down
    await voyage.repay(tus.address, 0, vault.address);
    const drawDownDetail3 = await voyage.getDrawDownDetail(
      vault.address,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail3);

    await voyage.repay(tus.address, 0, vault.address);
    const drawDownDetail4 = await voyage.getDrawDownDetail(
      vault.address,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail4);

    await voyage.repay(tus.address, 0, vault.address);
    const drawDownDetail5 = await voyage.getDrawDownDetail(
      vault.address,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail5);
  });

  it('Repay a non-debt should revert', async function () {
    const { juniorDepositToken, seniorDepositToken, vault, tus, voyage } =
      await setupTestSuite();

    const { owner } = await getNamedAccounts();

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMaxMargin(tus.address, '1000000000000000000000');
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyage.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyage.borrow(tus.address, '10000000000000000000', vault.address);

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const drawDownDetail = await voyage.getDrawDownDetail(
      vault.address,
      tus.address,
      0
    );

    await voyage.borrow(tus.address, '10000000000000000000', vault.address);

    // repay the first draw down
    await voyage.repay(tus.address, 0, vault.address);
    await voyage.repay(tus.address, 0, vault.address);
    await voyage.repay(tus.address, 0, vault.address);
    await expect(
      voyage.repay(tus.address, 0, vault.address)
    ).to.be.revertedWith('75');
  });
});

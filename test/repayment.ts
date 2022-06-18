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
      voyager,
    } = await setupTestSuite();

    // 100
    const depositAmount = '100000000000000000000';
    await voyager.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyager.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyager.depositMargin(
      owner,
      owner,
      tus.address,
      '100000000000000000000'
    );
    await voyager.borrow(tus.address, '10000000000000000000', vault.address);

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const vaultData = await voyager.getVaultData(owner, tus.address, owner);

    console.log('total debt: ', vaultData.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData.drawDownList.head.toString(),
      ',',
      vaultData.drawDownList.tail.toString(),
      ']'
    );

    const drawDownDetail = await voyager.getDrawDownDetail(
      owner,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail);

    await voyager.borrow(tus.address, '10000000000000000000', vault.address);

    const vaultData2 = await voyager.getVaultData(owner, tus.address, owner);

    console.log('total debt: ', vaultData2.totalDebt.toString());
    console.log(
      'draw down list: [',
      vaultData2.drawDownList.head.toString(),
      ',',
      vaultData2.drawDownList.tail.toString(),
      ']'
    );
    const drawDownDetail2 = await voyager.getDrawDownDetail(
      owner,
      tus.address,
      1
    );
    console.log('draw down 1: ');
    showDrawDown(drawDownDetail2);

    // repay the first draw down
    await voyager.repay(owner, tus.address, 0, vault.address);
    const drawDownDetail3 = await voyager.getDrawDownDetail(
      owner,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail3);

    await voyager.repay(owner, tus.address, 0, vault.address);
    const drawDownDetail4 = await voyager.getDrawDownDetail(
      owner,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail4);

    await voyager.repay(owner, tus.address, 0, vault.address);
    const drawDownDetail5 = await voyager.getDrawDownDetail(
      owner,
      tus.address,
      0
    );
    console.log('draw down 0: ');
    showDrawDown(drawDownDetail5);
  });

  it('Repay a non-debt should revert', async function () {
    const { juniorDepositToken, seniorDepositToken, vault, tus, voyager } =
      await setupTestSuite();

    const { owner } = await getNamedAccounts();

    // 100
    const depositAmount = '100000000000000000000';
    await voyager.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyager.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyager.depositMargin(
      owner,
      owner,
      tus.address,
      '100000000000000000000'
    );
    await voyager.borrow(tus.address, '10000000000000000000', vault.address);

    // increase seven days
    const sevenDays = 7 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [sevenDays]);
    await ethers.provider.send('evm_mine', []);

    const drawDownDetail = await voyager.getDrawDownDetail(
      owner,
      tus.address,
      0
    );

    await voyager.borrow(tus.address, '10000000000000000000', vault.address);

    // repay the first draw down
    await voyager.repay(owner, tus.address, 0, vault.address);
    await voyager.repay(owner, tus.address, 0, vault.address);
    await voyager.repay(owner, tus.address, 0, vault.address);
    await expect(
      voyager.repay(owner, tus.address, 0, vault.address)
    ).to.be.revertedWith('75');
  });
});

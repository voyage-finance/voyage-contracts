import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { toWad } from '../helpers/math';
import { Vault } from 'typechain/Vault';
import { VaultAssetFacet } from 'typechain/VaultAssetFacet';

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
      marketPlace,
    } = await setupTestSuite();

    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.deposit(crab.address, 0, depositAmount);
    await voyage.deposit(crab.address, 1, depositAmount);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      '1',
      vault,
      marketPlace.address,
      purchaseData
    );

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
      '2',
      vault,
      marketPlace.address,
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

    const loanDetail00 = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down 00: ');
    showLoan(loanDetail00);

    const loanDetail10 = await voyage.getLoanDetail(vault, crab.address, 1);
    console.log('draw down 10: ');
    showLoan(loanDetail10);

    // repay draw down 0
    await voyage.repay(crab.address, 0, vault);
    const loanDetail01 = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down 01: ');
    showLoan(loanDetail01);
    expect(loanDetail01.totalPrincipalPaid).to.equal('6666666666666666666');
    expect(loanDetail01.totalInterestPaid).to.equal('300000000000000000');

    const VaultAssetFacet = await ethers.getContractFactory('VaultAssetFacet');
    const vaultAssetFacet = await VaultAssetFacet.attach(vault);
    const withdrawableAssets = await vaultAssetFacet.withdrawableAsset(
      crab.address
    );
    console.log(withdrawableAssets.toString());
    expect(withdrawableAssets.length).to.equal(0);

    // repay draw down 0 again
    await voyage.repay(crab.address, 0, vault);
    const loanDetail02 = await voyage.getLoanDetail(vault, crab.address, 0);
    console.log('draw down 02: ');
    showLoan(loanDetail02);
    expect(loanDetail02.totalPrincipalPaid).to.equal(ethers.constants.Zero);
    expect(loanDetail02.totalPrincipalPaid).to.equal(ethers.constants.Zero);

    const withdrawableAssetsAfter = await vaultAssetFacet.withdrawableAsset(
      crab.address
    );
    expect(withdrawableAssetsAfter.length).to.equal(1);
    expect(withdrawableAssetsAfter[0]).to.equal(1);
  });
});

import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Reserve Deposit', function () {
  it('Deposit junior liquidity should return correct value', async function () {
    const { owner, juniorDepositToken, weth, crab, voyage } =
      await setupTestSuite();
    const depositAmount = '1000000000000000000';
    await expect(voyage.deposit(crab.address, 0, depositAmount))
      .to.emit(voyage, 'Deposit')
      .withArgs(crab.address, weth.address, owner, 0, depositAmount);
    const juniorTokenAmount = await juniorDepositToken.balanceOf(owner);
    expect(juniorTokenAmount).to.equal(ethers.BigNumber.from(depositAmount));

    // deposit again
    await expect(voyage.deposit(crab.address, 0, depositAmount))
      .to.emit(voyage, 'Deposit')
      .withArgs(crab.address, weth.address, owner, 0, depositAmount);
    const juniorTokenAmountAfter = await juniorDepositToken.balanceOf(owner);
    expect(juniorTokenAmountAfter).to.equal(
      ethers.BigNumber.from(depositAmount).mul(2)
    );

    const totalAssetJunior = await juniorDepositToken.totalAssets();
    expect(totalAssetJunior).to.equal(
      ethers.BigNumber.from(depositAmount).mul(2)
    );
  });

  it('Deposit senior liquidity should return correct value', async function () {
    const { owner, seniorDepositToken, crab, voyage } = await setupTestSuite();
    const depositAmount = '1000000000000000000';
    await voyage.deposit(crab.address, 1, depositAmount);
    const seniorTokenAmount = await seniorDepositToken.balanceOf(owner);
    expect(seniorTokenAmount).to.equal(ethers.BigNumber.from(depositAmount));

    // deposit again
    await voyage.deposit(crab.address, 1, depositAmount);
    const seniorTokenAmountAfterDeposit = await seniorDepositToken.balanceOf(
      owner
    );
    expect(seniorTokenAmountAfterDeposit).to.equal(
      ethers.BigNumber.from(depositAmount).mul(2)
    );

    const totalAssetSenior = await seniorDepositToken.totalAssets();
    expect(totalAssetSenior).to.equal(
      ethers.BigNumber.from(depositAmount).mul(2)
    );

    const maxClaimable = await seniorDepositToken.maximumClaimable(owner);
    expect(maxClaimable).to.equal(0);

    const shares = await seniorDepositToken.balanceOf(owner);
    expect(shares).to.equal(ethers.BigNumber.from(depositAmount).mul(2));

    const maxWithdraw = await seniorDepositToken.maxWithdraw(owner);
    expect(maxWithdraw).to.equal(ethers.BigNumber.from(depositAmount).mul(2));

    const maxRedeem = await seniorDepositToken.maxRedeem(owner);
    expect(maxRedeem).to.equal(ethers.BigNumber.from(depositAmount).mul(2));

    const unbonding = await seniorDepositToken.unbonding(owner);
    expect(unbonding).to.equal(0);

    const totalUnbondingAsset = await seniorDepositToken.totalUnbondingAsset();
    expect(totalUnbondingAsset).to.equal(0);
  });
});

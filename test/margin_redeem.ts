import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Security Redeem', function () {
  it('Margin redeem within lockup time should throw error', async function () {
    const { voyager, tus, owner } = await setupTestSuite();
    await voyager.depositMargin(owner, tus.address, '10000000000000000000');
    const eligibleAmount = await voyager.getWithdrawableDeposit(
      owner,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal('0');
    await expect(
      voyager.redeemMargin(owner, tus.address, '1000000000000000000')
    ).to.be.revertedWith(
      'Vault: cannot redeem more than withdrawable deposit amount'
    );
  });

  it('Security redeem with no slash should return correct value', async function () {
    const { voyager, tus, owner } = await setupTestSuite();
    await voyager.depositMargin(owner, tus.address, '10000000000000000000');

    const tenDay = 10 * 24 * 60 * 60;

    await ethers.provider.send('evm_increaseTime', [tenDay]);
    // @ts-ignore
    await ethers.provider.send('evm_mine');

    const eligibleAmount = await voyager.getWithdrawableDeposit(
      owner,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal('10000000000000000000');
    await voyager.redeemMargin(owner, tus.address, '1000000000000000000');
  });
});

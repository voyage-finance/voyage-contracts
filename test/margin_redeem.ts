import { decimals, MAX_UINT_256, RAY } from '../helpers/math';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Security Redeem', function () {
  it('Unused margin should be redeemable', async function () {
    const { voyager, tus, owner, vault } = await setupTestSuite();
    const margin = BigNumber.from(100).mul(decimals(18));
    await voyager.depositMargin(vault.address, tus.address, margin);
    const eligibleAmount = await voyager.getWithdrawableMargin(
      vault.address,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal(margin.toString());

    const escrow = await ethers.getContractAt(
      'MarginEscrow',
      await vault.marginEscrow(tus.address)
    );
    await escrow.approve(vault.address, MAX_UINT_256);

    await expect(
      voyager.redeemMargin(vault.address, tus.address, '1000000000000000000')
    ).not.to.be.reverted;
  });

  it('Used margin should not be redeemable', async function () {
    const { voyager, tus, owner, vault } = await setupTestSuite();
    // deposit some funds
    const deposit = BigNumber.from(100000).mul(decimals(18));
    await voyager.deposit(tus.address, 0, deposit, owner);
    await voyager.deposit(tus.address, 1, deposit, owner);
    // maximum borrow amount should be 100 / 0.1 = 1000
    const margin = BigNumber.from(100).mul(decimals(18));
    await voyager.depositMargin(vault.address, tus.address, margin);
    const borrow = BigNumber.from(1000).mul(decimals(18));
    await voyager.borrow(tus.address, borrow, vault.address);

    const availableCredit = await voyager.getAvailableCredit(
      vault.address,
      tus.address
    );
    expect(availableCredit).to.equal('0');
    const eligibleAmount = await voyager.getWithdrawableMargin(
      vault.address,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal('0');

    const escrow = await ethers.getContractAt(
      'MarginEscrow',
      await vault.marginEscrow(tus.address)
    );
    await escrow.approve(vault.address, MAX_UINT_256);

    await expect(
      voyager.redeemMargin(vault.address, tus.address, '1000000000000000000')
    ).to.be.reverted;
  });

  it('Partial redemption of unused margin should work', async function () {
    const { voyager, tus, owner, vault } = await setupTestSuite();
    // deposit some funds
    const deposit = BigNumber.from(100000).mul(decimals(18));
    await voyager.deposit(tus.address, 0, deposit, owner);
    await voyager.deposit(tus.address, 1, deposit, owner);
    // maximum borrow amount should be 100 / 0.1 = 1000
    const margin = BigNumber.from(100).mul(decimals(18));
    await voyager.depositMargin(vault.address, tus.address, margin);
    // borrow 500
    const borrow = BigNumber.from(500).mul(decimals(18));
    await voyager.borrow(tus.address, borrow, vault.address);
    const vaultBalance = await tus.balanceOf(vault.address);
    expect(vaultBalance.div(decimals(18))).to.equal('500');
    const vaultDebt = await vault.totalDebt(tus.address);

    const expectedMinimumMargin = vaultDebt.div(10);
    const eligibleAmount = await voyager.getWithdrawableMargin(
      vault.address,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal(margin.sub(expectedMinimumMargin));

    const escrow = await ethers.getContractAt(
      'MarginEscrow',
      await vault.marginEscrow(tus.address)
    );
    await escrow.approve(vault.address, MAX_UINT_256);

    await expect(
      voyager.redeemMargin(vault.address, tus.address, '1000000000000000000')
    ).not.to.be.reverted;
  });
});

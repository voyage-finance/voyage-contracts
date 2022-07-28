import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { decimals, MAX_UINT_256 } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Margin Redeem', function () {
  it('Unused margin should be redeemable', async function () {
    const { voyage, tus, crab, owner } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    const margin = BigNumber.from(100).mul(decimals(18));
    await voyage.depositMargin(vault, crab.address, margin);
    const eligibleAmount = await voyage.getWithdrawableMargin(
      vault,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal(margin.toString());

    const escrowAddr = await voyage.getVaultEscrowAddr(owner, tus.address);
    const escrow = await ethers.getContractAt(
      'MarginEscrow',

      escrowAddr[1]
    );
    await escrow.approve(vault, MAX_UINT_256);

    await expect(
      voyage.redeemMargin(vault, crab.address, '1000000000000000000')
    ).not.to.be.reverted;
  });

  it('Used margin should not be redeemable', async function () {
    const { voyage, tus, crab, owner } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    // deposit some funds
    const deposit = BigNumber.from(100000).mul(decimals(18));
    await voyage.deposit(crab.address, 0, deposit);
    await voyage.deposit(crab.address, 1, deposit);
    // maximum borrow amount should be 100 / 0.1 = 1000
    const margin = BigNumber.from(100).mul(decimals(18));
    await voyage.depositMargin(vault, crab.address, margin);
    const borrow = BigNumber.from(1000).mul(decimals(18));
    await voyage.borrow(crab.address, borrow, vault);

    const availableCredit = await voyage.getAvailableCredit(
      vault,
      crab.address
    );
    expect(availableCredit).to.equal('0');
    const eligibleAmount = await voyage.getWithdrawableMargin(
      vault,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal('0');
    const escrowAddr = await voyage.getVaultEscrowAddr(owner, tus.address);

    const escrow = await ethers.getContractAt('MarginEscrow', escrowAddr[1]);
    await escrow.approve(vault, MAX_UINT_256);

    await expect(
      voyage.redeemMargin(vault, crab.address, '1000000000000000000')
    ).to.be.reverted;
  });

  it('Partial redemption of unused margin should work', async function () {
    const { voyage, tus, crab, owner } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    // deposit some funds
    const deposit = BigNumber.from(100000).mul(decimals(18));
    await voyage.deposit(crab.address, 0, deposit);
    await voyage.deposit(crab.address, 1, deposit);
    // maximum borrow amount should be 100 / 0.1 = 1000
    const margin = BigNumber.from(100).mul(decimals(18));
    await voyage.depositMargin(vault, crab.address, margin);
    // borrow 500
    const borrow = BigNumber.from(500).mul(decimals(18));
    await voyage.borrow(crab.address, borrow, vault);
    const escrowAddr = await voyage.getVaultEscrowAddr(owner, tus.address);
    const vaultBalance = await tus.balanceOf(escrowAddr[0]);
    expect(vaultBalance.div(decimals(18))).to.equal('500');
    const bp = await ethers.getContractFactory('VaultDataFacet');
    const vaultInstance = await bp.attach(vault);
    const vaultDebt = await vaultInstance.totalDebt(crab.address);

    const expectedMinimumMargin = vaultDebt.div(10);
    const eligibleAmount = await voyage.getWithdrawableMargin(
      vault,
      tus.address,
      owner
    );
    expect(eligibleAmount).to.equal(margin.sub(expectedMinimumMargin));

    const escrow = await ethers.getContractAt(
      'MarginEscrow',
      await vaultInstance.marginEscrow(tus.address)
    );
    await escrow.approve(vault, MAX_UINT_256);

    await expect(
      voyage.redeemMargin(vault, crab.address, '1000000000000000000')
    ).not.to.be.reverted;
  });
});

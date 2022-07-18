import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { decimals, formatBN } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
const { BigNumber } = ethers;

describe('Borrow', function () {
  it('Borrow with wrong vault address should revert', async function () {
    const { tus, voyage } = await setupTestSuite();

    await expect(
      voyage.borrow(tus.address, '10000000000000000000', voyage.address)
    ).to.be.revertedWith('Unauthorised()');
  });

  it('Borrow with insufficient reserve should revert', async function () {
    const { tus, voyage } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    const vaultAddr = await voyage.getVault(owner);
    await expect(
      voyage.borrow(tus.address, '10000000000000000000', vaultAddr)
    ).to.be.revertedWith('InsufficientLiquidity()');
  });

  it('Does not panic when credit < debt', async () => {
    const { tus, voyage } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    // deposit sufficient reserve
    const dec = await tus.decimals();
    const deposit = BigNumber.from(10_000_000).mul(decimals(dec));
    await voyage.deposit(tus.address, 1, deposit, owner);
    const vaultAddr = await voyage.getVault(owner);
    const margin = ethers.BigNumber.from(100).mul(decimals(dec));
    await voyage.depositMargin(vaultAddr, tus.address, margin);
    const borrowAmount = margin.mul(10);
    await voyage.borrow(tus.address, borrowAmount, vaultAddr);
    await expect(
      voyage.borrow(tus.address, margin.mul(11), vaultAddr)
    ).to.be.revertedWith('InsufficientCreditLimit()');
  });

  it('Insufficient credit limit should revert', async function () {
    const { tus, voyage, owner } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    // deposit sufficient reserve
    const depositAmount = '100000000000000000000';
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    await expect(
      voyage.borrow(tus.address, '10000000000000000000', vault)
    ).to.be.revertedWith('InsufficientCreditLimit()');
  });

  it('Sufficient credit limit should return correct value', async function () {
    const { owner, tus, voyage } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    // 100
    const depositAmount = '100000000000000000000';
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    // 100
    const margin = ethers.BigNumber.from('100000000000000000000');
    await voyage.depositMargin(vault, tus.address, margin);
    // 10
    const borrow = ethers.BigNumber.from('10000000000000000000');
    await voyage.borrow(tus.address, borrow, vault);
    const escrowAddr = await voyage.getVaultEscrowAddr(owner, tus.address);
    const vaultBalance = await tus.balanceOf(escrowAddr[0]);
    expect(vaultBalance).to.equal(borrow);
    const pool = await voyage.getPoolData(tus.address);
    console.log('totalDebt: ', formatBN(pool.totalDebt, 18));
    expect(pool.totalDebt).to.equal(borrow);
    const creditLimit = await voyage.getCreditLimit(vault, tus.address);
    console.log('credit limit: ', formatBN(creditLimit, 18));
    expect(creditLimit).to.equal(margin.mul(10));
    const availableCredit = await voyage.getAvailableCredit(vault, tus.address);
    console.log('available credit: ', formatBN(availableCredit, 18));
    await voyage.borrow(tus.address, borrow, vault);
    const vaultBalance2 = await tus.balanceOf(vault);
    console.log('vault balance: ', vaultBalance2.toString());
    console.log('available credit: ', availableCredit.toString());
  });
});

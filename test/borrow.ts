import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { decimals } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
const { BigNumber } = ethers;

describe('Borrow', function () {
  it('Borrow with wrong vault address should revert', async function () {
    const { tus, voyage } = await setupTestSuite();

    await expect(
      voyage.borrow(tus.address, '10000000000000000000', voyage.address)
    ).to.be.revertedWith('73');
  });

  it('Borrow with insufficient reserve should revert', async function () {
    const { tus, voyage } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    const vaultAddr = await voyage.getVault(owner);
    await expect(
      voyage.borrow(tus.address, '10000000000000000000', vaultAddr)
    ).to.be.revertedWith('70');
  });

  it('Does not panic when credit < debt', async () => {
    const { tus, voyage } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    // deposit sufficient reserve
    const dec = await tus.decimals();
    const deposit = BigNumber.from(10_000_000).mul(decimals(dec));

    await voyage.deposit(tus.address, 1, deposit, owner);
    await voyage.setMaxMargin(tus.address, deposit);
    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    const vaultAddr = await voyage.getVault(owner);
    const margin = ethers.BigNumber.from(100).mul(decimals(dec));
    await voyage.depositMargin(vaultAddr, tus.address, margin);
    const borrowAmount = margin.mul(10);
    await voyage.borrow(tus.address, borrowAmount, vaultAddr);
    await expect(
      voyage.borrow(tus.address, margin.mul(11), vaultAddr)
    ).to.be.revertedWith('71');
  });

  it('Insufficient credit limit should revert', async function () {
    const { tus, voyage, vault } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    // deposit sufficient reserve
    const depositAmount = '100000000000000000000';
    await voyage.deposit(tus.address, 1, depositAmount, owner);

    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await expect(
      voyage.borrow(tus.address, '10000000000000000000', vault.address)
    ).to.be.revertedWith('71');
  });

  it('Sufficient credit limit should return correct value', async function () {
    const { juniorDepositToken, seniorDepositToken, vault, tus, voyage } =
      await setupTestSuite();
    const { owner } = await getNamedAccounts();
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
    const escrowAddr = await voyage.getVaultEscrowAddr(owner, tus.address);
    const vaultBalance = await tus.balanceOf(escrowAddr[0]);
    expect(vaultBalance).to.equal(BigNumber.from('10000000000000000000'));
    const creditLimit = await voyage.getCreditLimit(vault.address, tus.address);
    const availableCredit = await voyage.getAvailableCredit(
      vault.address,
      tus.address
    );
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
    await voyage.borrow(tus.address, '10000000000000000000', vault.address);
    const vaultBalance2 = await tus.balanceOf(vault.address);
    console.log('vault balance: ', vaultBalance2.toString());
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
  });
});

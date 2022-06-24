import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { decimals } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
const { BigNumber } = ethers;

describe('Borrow', function () {
  it('Borrow with wrong vault address should revert', async function () {
    const { tus, voyager } = await setupTestSuite();

    await expect(
      voyager.borrow(tus.address, '10000000000000000000', voyager.address)
    ).to.be.revertedWith('73');
  });

  it('Borrow with insufficient reserve should revert', async function () {
    const { tus, voyager } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    const vaultAddr = await voyager.getVault(owner);
    await expect(
      voyager.borrow(tus.address, '10000000000000000000', vaultAddr)
    ).to.be.revertedWith('70');
  });

  it('Does not panic when credit < debt', async () => {
    const { tus, voyager } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    // deposit sufficient reserve
    const dec = await tus.decimals();
    const deposit = BigNumber.from(10_000_000).mul(decimals(dec));

    await voyager.deposit(tus.address, 1, deposit, owner);
    await voyager.setMaxMargin(tus.address, deposit);
    await voyager.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    const vaultAddr = await voyager.getVault(owner);
    const margin = ethers.BigNumber.from(100).mul(decimals(dec));
    await voyager.depositMargin(owner, tus.address, margin);
    const borrowAmount = margin.mul(10);
    await voyager.borrow(tus.address, borrowAmount, vaultAddr);
    await expect(
      voyager.borrow(tus.address, margin.mul(11), vaultAddr)
    ).to.be.revertedWith('71');
  });

  it('Insufficient credit limit should revert', async function () {
    const { tus, voyager, vault } = await setupTestSuite();
    const { owner } = await getNamedAccounts();
    // deposit sufficient reserve
    const depositAmount = '100000000000000000000';
    await voyager.deposit(tus.address, 1, depositAmount, owner);

    await voyager.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await expect(
      voyager.borrow(tus.address, '10000000000000000000', vault.address)
    ).to.be.revertedWith('71');
  });

  it('Sufficient credit limit should return correct value', async function () {
    const { juniorDepositToken, seniorDepositToken, vault, tus, voyager } =
      await setupTestSuite();
    const { owner } = await getNamedAccounts();
    const depositAmount = '100000000000000000000';
    await voyager.setMaxMargin(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyager.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyager.depositMargin(owner, tus.address, '100000000000000000000');
    await voyager.borrow(tus.address, '10000000000000000000', vault.address);
    const vaultBalance = await tus.balanceOf(vault.address);
    expect(vaultBalance).to.equal(BigNumber.from('10000000000000000000'));
    const creditLimit = await voyager.getCreditLimit(owner, tus.address);
    const availableCredit = await voyager.getAvailableCredit(
      owner,
      tus.address
    );
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
    await voyager.borrow(tus.address, '10000000000000000000', vault.address);
    const vaultBalance2 = await tus.balanceOf(vault.address);
    console.log('vault balance: ', vaultBalance2.toString());
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
  });
});

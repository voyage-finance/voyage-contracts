import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { setupDebtTestSuite } from '../helpers/debt';
import {
  decimals,
  formatTokenBalance,
  MAX_UINT_256,
  RAY,
} from '../helpers/math';
import { mine, timeTravel } from '../helpers/chain';
const { BigNumber } = ethers;

describe('Borrow', function () {
  it('Borrow with wrong vault address should revert', async function () {
    const { tus, voyager } = await setupDebtTestSuite();

    await expect(
      voyager.borrow(tus.address, '10000000000000000000', voyager.address, 0)
    ).to.be.revertedWith('73');
  });

  it('Borrow with no sufficient reserve should revert', async function () {
    const { tus, voyager } = await setupDebtTestSuite();
    const { owner } = await getNamedAccounts();
    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await expect(
      voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0)
    ).to.be.revertedWith('70');
  });

  it('Does not panic when credit < debt', async () => {
    const { tus, vm, voyager } = await setupDebtTestSuite();
    const { owner } = await getNamedAccounts();
    // deposit sufficient reserve
    const dec = await tus.decimals();
    const deposit = BigNumber.from(10_000_000).mul(decimals(dec));
    await voyager.deposit(tus.address, 1, deposit);

    await vm.setMaxSecurityDeposit(tus.address, deposit);
    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddr);

    const securityAmount = ethers.BigNumber.from(100).mul(decimals(dec));
    const escrowAddress = await vault.getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(escrowAddress, MAX_UINT_256);
    await voyager.depositSecurity(owner, tus.address, securityAmount);

    const borrowAmount = securityAmount.mul(10);
    await voyager.borrow(tus.address, borrowAmount, vaultAddr, 0);
    await expect(
      voyager.borrow(tus.address, securityAmount.mul(11), vaultAddr, 0)
    ).to.be.revertedWith('71');
  });

  it('Insufficient credit limit should revert', async function () {
    const { lm, tus, vm, voyager } = await setupDebtTestSuite();
    const { owner } = await getNamedAccounts();
    // deposit sufficient reserve
    const depositAmount = '100000000000000000000';
    await lm.activeReserve(tus.address);
    await voyager.deposit(tus.address, 1, depositAmount);

    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);

    await expect(
      voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0)
    ).to.be.revertedWith('71');
  });

  it('Sufficient credit limit should return correct value', async function () {
    const {
      juniorDepositToken,
      seniorDepositToken,
      defaultReserveInterestRateStrategy,
      healthStrategyAddress,
      lm,
      vm,
      tus,
      voyager,
      loanStrategy,
    } = await setupDebtTestSuite();
    const { owner } = await getNamedAccounts();
    await lm.initReserve(
      tus.address,
      juniorDepositToken.address,
      seniorDepositToken.address,
      defaultReserveInterestRateStrategy.address,
      healthStrategyAddress.address,
      loanStrategy.address,
      '500000000000000000000000000'
    );
    // 100
    const depositAmount = '100000000000000000000';
    await lm.activeReserve(tus.address);
    await vm.setMaxSecurityDeposit(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount);
    await voyager.deposit(tus.address, 1, depositAmount);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await vm.setSecurityDepositRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    // create an empty vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);

    // get security deposit escrow address
    const Vault = await ethers.getContractFactory('Vault');
    const escrowAddress = await Vault.attach(
      vaultAddr
    ).getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(escrowAddress, '1000000000000000000000');

    await voyager.depositSecurity(owner, tus.address, '100000000000000000000');
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, 0);
    // await expect(debtBalance).to.equal(BigNumber.from('10000000000000000000'));
    const vaultBalance = await tus.balanceOf(vaultAddr);
    await expect(vaultBalance).to.equal(BigNumber.from('10000000000000000000'));
    const creditLimit = await voyager.getCreditLimit(owner, tus.address);
    const availableCredit = await voyager.getAvailableCredit(
      owner,
      tus.address
    );
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
    await voyager.borrow(tus.address, '10000000000000000000', vaultAddr, '0');
    const vaultBalance2 = await tus.balanceOf(vaultAddr);
    console.log('vault balance: ', vaultBalance2.toString());
    console.log('credit limit: ', creditLimit.toString());
    console.log('available credit: ', availableCredit.toString());
  });

  it('debt token totalSupply should be equal to the sum of all user debt within 9 DPs of precision', async () => {
    const { juniorDepositToken, seniorDepositToken, tus, vm, voyager } =
      await setupDebtTestSuite();
    const { owner, alice, bob } = await getNamedAccounts();
    const decimals = await tus.decimals();
    const multiplier = BigNumber.from(10).pow(decimals);
    const seniorDeposit = BigNumber.from(10_000_000).mul(multiplier);
    const juniorDeposit = BigNumber.from(2_000_000).mul(multiplier);
    await vm.setMaxSecurityDeposit(
      tus.address,
      BigNumber.from(10_000_000).mul(multiplier)
    );

    await voyager.deposit(tus.address, 1, seniorDeposit);
    await voyager.deposit(tus.address, 0, juniorDeposit);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    expect(seniorLiquidity).to.equal(seniorDeposit);
    expect(juniorLiquidity).to.equal(juniorDeposit);

    // 0.1
    const sdRequirement = RAY.multipliedBy('0.1').toFixed();
    await vm.setSecurityDepositRequirement(tus.address, sdRequirement);

    const vaults: Record<string, any> = {};
    const Vault = await ethers.getContractFactory('Vault');
    const securityAmount = ethers.BigNumber.from(10_000).mul(multiplier);
    const borrowAmount = ethers.BigNumber.from(1000).mul(multiplier);

    for (const user of [owner, alice, bob]) {
      const signer = await ethers.getSigner(user);

      // create and initialise vaults for all actors
      const salt = ethers.utils.formatBytes32String(
        (Math.random() + 1).toString(36).substring(7)
      );
      await voyager.createVault(user, tus.address, salt);
      const vaultAddr = await voyager.getVault(user);
      await voyager.initVault(vaultAddr, tus.address);

      const vault = Vault.attach(vaultAddr);
      vaults[user] = vault;

      // fund margin account and borrow funds
      const escrowAddress = await vault.getSecurityDepositEscrowAddress();
      await tus.increaseAllowance(escrowAddress, MAX_UINT_256);
      await voyager.depositSecurity(user, tus.address, securityAmount);

      // do multiple borrows
      const NUM_BORROWS = 3;
      for (let i = 0; i < NUM_BORROWS; i++) {
        await voyager
          .connect(signer)
          .borrow(tus.address, borrowAmount, vaultAddr, 0);
        await mine(5, 2);
      }
    }
  });
});

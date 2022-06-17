import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Security Deposit', function () {
  it('Non Voyager call VaultManager should throw error', async function () {
    const { tus, voyager } = await setupTestSuite();

    await expect(
      voyager.setMaxSecurityDeposit(tus.address, '100000000000000000000')
    ).to.be.revertedWith('Only the proxy can call');
  });

  it('Security deposit setup should return correct value', async function () {
    const { tus, voyager } = await setupTestSuite();
    await voyager.setMaxSecurityDeposit(tus.address, '100000000000000000000');
    const amountAfterSetting = await voyager.getVaultConfig(tus.address);
    expect(amountAfterSetting.maxSecurityDeposit.toString()).to.equal(
      '100000000000000000000'
    );
  });

  it('Security deposit should return correct value', async function () {
    const { owner, tus, voyager } = await setupTestSuite();
    // create vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddr = await voyager.getVault(owner);
    await voyager.initVault(vaultAddr, tus.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = await Vault.attach(vaultAddr);
    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();
    await tus.increaseAllowance(
      securityDepositEscrowAddress,
      '10000000000000000000000'
    );

    await voyager.setMaxSecurityDeposit(tus.address, '100000000000000000000');
    const SecurityDepositEscrow = await ethers.getContractFactory(
      'SecurityDepositEscrow'
    );
    const securityDepositEscrow = await SecurityDepositEscrow.attach(
      securityDepositEscrowAddress
    );
    const depositAmount = await securityDepositEscrow.getDepositAmount(
      tus.address
    );
    expect(depositAmount).to.equal('0');

    await voyager.depositSecurity(owner, tus.address, '10000000000000000000');
    const depositAmountAfter = await securityDepositEscrow.getDepositAmount(
      tus.address
    );
    expect(depositAmountAfter).to.equal('10000000000000000000');

    const SecurityDepositToken = await ethers.getContractFactory(
      'SecurityDepositToken'
    );
    const securityDepositToken = SecurityDepositToken.attach(
      await vault.getSecurityDepositTokenAddress()
    );
    const balanceOfSponsor = await securityDepositToken.balanceOf(owner);
    expect(balanceOfSponsor).to.equal('10000000000000000000');
  });
});

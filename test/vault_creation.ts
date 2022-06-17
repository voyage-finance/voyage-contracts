import { ethers } from 'hardhat';
import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault Creation', function () {
  it('New user should have zero address vault', async function () {
    const { owner, voyager } = await setupTestSuite();
    expect(await voyager.getVault(owner)).to.equal(
      '0x0000000000000000000000000000000000000000'
    );
  });

  it('Create Vault should return a valid vault contract', async function () {
    const { owner, tus, voyager } = await setupTestSuite();
    // create vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddress = await voyager.getVault(owner);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
  });

  it('Created Vault should have own a valid escrow contract', async function () {
    const { owner, tus, voyager } = await setupTestSuite();
    // create vault
    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddress = await voyager.getVault(owner);
    await voyager.initVault(vaultAddress, tus.address);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
    const SecurityDepositEscrow = await ethers.getContractFactory(
      'SecurityDepositEscrow'
    );
    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();
    const securityDepositEscrow = SecurityDepositEscrow.attach(
      securityDepositEscrowAddress
    );
    expect(await securityDepositEscrow.getVersion()).to.equal(
      'SecurityDepositEscrow 0.0.1'
    );
  });
});

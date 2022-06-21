import { ethers } from 'hardhat';
import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault Creation', function () {
  it('New user should have zero address vault', async function () {
    const { alice, voyager } = await setupTestSuite();
    expect(await voyager.getVault(alice)).to.equal(
      '0x0000000000000000000000000000000000000000'
    );
  });

  it('Create Vault should return a valid vault contract', async function () {
    const { alice, voyager, tus } = await setupTestSuite();
    await voyager.createVault(voyager.address, alice, tus.address);
    const vaultAddress = await voyager.getVault(alice);
    expect(vaultAddress).not.to.equal(ethers.constants.AddressZero);
  });

  it('Created Vault should have own a valid escrow contract', async function () {
    const { alice, tus, voyager } = await setupTestSuite();
    await voyager.createVault(voyager.address, alice, tus.address);
    const vaultAddress = await voyager.getVault(alice);
    const vault = await ethers.getContractAt('Vault', vaultAddress);
    const marginEscrowAddress = await vault.getMarginEscrowAddress();
    const marginEscrow = await ethers.getContractAt(
      'MarginEscrow',
      marginEscrowAddress
    );
    expect(await marginEscrow.getVersion()).to.equal('MarginEscrow 0.0.1');
  });
});

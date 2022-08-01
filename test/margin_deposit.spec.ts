import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Margin Deposit', function () {
  it('Non-admin should not be authorised to set max security deposit', async function () {
    const { alice, crab, voyage } = await setupTestSuite();
    const signer = await ethers.getSigner(alice);
    await expect(
      voyage.connect(signer).setMarginParams(crab.address, 0, 1000, 0.1 * 1e4)
    ).to.be.revertedWith('call is not authorised');
  });

  it('Security deposit setup should return correct value', async function () {
    const { crab, voyage, owner } = await setupTestSuite();
    voyage.setMarginParams(crab.address, 0, 1000, 0.1 * 1e4);
    const vault = await voyage.getVault(owner);
    const amountAfterSetting = await voyage.getVaultConfig(crab.address, vault);
    expect(amountAfterSetting.maxMargin.toString()).to.equal(
      '1000000000000000000000'
    );
  });

  it('Security deposit should return correct value', async function () {
    const { tus, crab, voyage, owner } = await setupTestSuite();
    const vault = await voyage.getVault(owner);
    voyage.setMarginParams(crab.address, 0, 1000, 0.1 * 1e4);
    const escrowAddr = await voyage.getVaultEscrowAddr(owner, tus.address);
    const marginEscrow = await ethers.getContractAt(
      'MarginEscrow',
      escrowAddr[1]
    );
    const depositAmount = await marginEscrow.totalMargin();
    expect(depositAmount).to.equal('0');

    await voyage.depositMargin(vault, crab.address, '10000000000000000000');
    const depositAmountAfter = await marginEscrow.totalMargin();
    expect(depositAmountAfter).to.equal('10000000000000000000');
  });
});

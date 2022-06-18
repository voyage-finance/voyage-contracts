import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Margin Deposit', function () {
  it('Non-admin should not be authorised to set max security deposit', async function () {
    const { alice, tus, voyager } = await setupTestSuite();
    const signer = await ethers.getSigner(alice);
    await expect(
      voyager
        .connect(signer)
        .setMaxSecurityDeposit(tus.address, '100000000000000000000')
    ).to.be.revertedWith('Not protocol admin');
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
    const { owner, tus, vault, voyager } = await setupTestSuite();

    await voyager.setMaxSecurityDeposit(tus.address, '100000000000000000000');

    const securityDepositEscrowAddress =
      await vault.getSecurityDepositEscrowAddress();
    const securityDepositEscrow = await ethers.getContractAt(
      'SecurityDepositEscrow',
      securityDepositEscrowAddress
    );
    const depositAmount = await securityDepositEscrow.getDepositAmount(
      tus.address
    );
    expect(depositAmount).to.equal('0');

    await voyager.depositMargin(
      owner,
      owner,
      tus.address,
      '10000000000000000000'
    );
    const depositAmountAfter = await securityDepositEscrow.getDepositAmount(
      tus.address
    );
    expect(depositAmountAfter).to.equal('10000000000000000000');

    const securityDepositToken = await ethers.getContractAt(
      'SecurityDepositToken',
      await vault.getSecurityDepositTokenAddress()
    );
    const balanceOfSponsor = await securityDepositToken.balanceOf(owner);
    expect(balanceOfSponsor).to.equal('10000000000000000000');
  });
});

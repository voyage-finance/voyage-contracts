import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Margin Deposit', function () {
  it('Non-admin should not be authorised to set max security deposit', async function () {
    const { alice, tus, voyager } = await setupTestSuite();
    const signer = await ethers.getSigner(alice);
    await expect(
      voyager.connect(signer).setMaxMargin(tus.address, '100000000000000000000')
    ).to.be.revertedWith('call is not authorised');
  });

  it('Security deposit setup should return correct value', async function () {
    const { tus, voyager } = await setupTestSuite();
    await voyager.setMaxMargin(tus.address, '100000000000000000000');
    const amountAfterSetting = await voyager.getVaultConfig(tus.address);
    expect(amountAfterSetting.maxMargin.toString()).to.equal(
      '100000000000000000000'
    );
  });

  it('Security deposit should return correct value', async function () {
    const { owner, tus, vault, voyager } = await setupTestSuite();
    await voyager.setMaxMargin(tus.address, '100000000000000000000');
    const marginEscrowAddress = await vault.marginEscrow(tus.address);
    const marginEscrow = await ethers.getContractAt(
      'MarginEscrow',
      marginEscrowAddress
    );
    const depositAmount = await marginEscrow.totalMargin();
    expect(depositAmount).to.equal('0');

    await voyager.depositMargin(owner, tus.address, '10000000000000000000');
    const depositAmountAfter = await marginEscrow.totalMargin();
    expect(depositAmountAfter).to.equal('10000000000000000000');
  });
});

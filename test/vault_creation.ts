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

  it('Owner creates vault should return a valid vault contract', async function () {
    const { alice, voyager, tus } = await setupTestSuite();
    await voyager.createVault(alice, tus.address);
    const vaultAddress = await voyager.getVault(alice);
    expect(vaultAddress).not.to.equal(ethers.constants.AddressZero);
  });

  it('Non owner creates vault should revert', async function () {
    const { alice, voyager, tus } = await setupTestSuite();
    await expect(
      voyager
        .connect(await ethers.getSigner(alice))
        .createVault(alice, tus.address)
    ).to.be.revertedWith('call is not authorised');
  });
});

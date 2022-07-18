import { expect } from 'chai';
import { ethers } from 'hardhat';
import { toWad } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault', function () {
  it('Vault owner should be able to withdraw rewards', async function () {
    const { tus, voyage, owner, alice } = await setupTestSuite();
    const vaultAddr = await voyage.getVault(owner);
    await tus.transfer(vaultAddr, toWad(100));
    const VaultAssetFacet = await ethers.getContract('VaultAssetFacet');
    const vaultAssetFacet = await VaultAssetFacet.attach(vaultAddr);
    await vaultAssetFacet.withdrawRewards(tus.address, alice, toWad(100));
    const balanceAfter = await tus.balanceOf(alice);
    expect(balanceAfter.toString()).to.equal('100000000000000000000');
  });

  it('Non vault owner should not be able to withdraw rewards', async function () {
    const { tus, voyage, owner, alice } = await setupTestSuite();
    const vaultAddr = await voyage.getVault(owner);
    await tus.transfer(vaultAddr, toWad(100));
    const VaultAssetFacet = await ethers.getContract('VaultAssetFacet');
    const vaultAssetFacet = await VaultAssetFacet.attach(vaultAddr);
    await expect(
      vaultAssetFacet
        .connect(await ethers.getSigner(alice))
        .withdrawRewards(tus.address, alice, toWad(100))
    ).to.be.revertedWith('unauthorised');
  });
});

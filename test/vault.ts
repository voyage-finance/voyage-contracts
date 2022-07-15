import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { decimals, toWadValue } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';
const { BigNumber } = ethers;

describe('Vault', function () {
  it('Vault owner should be able to withdraw rewards', async function () {
    const { tus, voyage, owner, alice } = await setupTestSuite();
    const vaultAddr = await voyage.getVault(owner);
    await tus.transfer(vaultAddr, toWadValue(100));
    const VaultAssetFacet = await ethers.getContract('VaultAssetFacet');
    const vaultAssetFacet = await VaultAssetFacet.attach(vaultAddr);
    await vaultAssetFacet.withdrawRewards(tus.address, alice, toWadValue(100));
    const balanceAfter = await tus.balanceOf(alice);
    expect(balanceAfter.toString()).to.equal('100000000000000000000');
  });

  it('Non vault owner should not be able to withdraw rewards', async function () {
    const { tus, voyage, owner, alice } = await setupTestSuite();
    const vaultAddr = await voyage.getVault(owner);
    await tus.transfer(vaultAddr, toWadValue(100));
    const VaultAssetFacet = await ethers.getContract('VaultAssetFacet');
    const vaultAssetFacet = await VaultAssetFacet.attach(vaultAddr);
    await expect(
      vaultAssetFacet
        .connect(await ethers.getSigner(alice))
        .withdrawRewards(tus.address, alice, toWadValue(100))
    ).to.be.revertedWith('unauthorised');
  });
});

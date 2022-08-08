import { expect } from 'chai';
import { ethers } from 'hardhat';
import { toWad } from '../helpers/math';
import { randomBytes } from 'crypto';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault', function () {
  it('Granted acount should be able to create vault', async function () {
    const { voyage, alice } = await setupTestSuite();
    var abi = ['function createVault(address,bytes20)'];
    var iface = new ethers.utils.Interface(abi);
    var selector = iface.getSighash('createVault');

    await voyage.grantPermission(alice, voyage.address, selector);
    const salt = randomBytes(20);
    await voyage
      .connect(await ethers.getSigner(alice))
      .createVault(alice, salt);
    const deployedVault = await voyage.getVault(alice);
    console.log('deployed vault address for alice: ', deployedVault);
  });

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

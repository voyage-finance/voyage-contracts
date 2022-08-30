import { expect } from 'chai';
import { randomBytes } from 'crypto';
import { deployments, ethers } from 'hardhat';
import { ZERO_ADDRESS } from '../helpers/constants';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault', function () {
  it('should revert if passing 0 as vault impl', async function () {
    const { voyage } = await setupTestSuite();
    await expect(
      voyage.setVaultImpl(ethers.constants.AddressZero)
    ).to.be.revertedWithCustomError(voyage, 'InvalidVaultImpl');
  });

  it('should revert if passing a garbage address as vault impl', async function () {
    const { voyage } = await setupTestSuite();
    const garbageAddress = ethers.utils.hexlify(ethers.utils.randomBytes(20));
    await expect(
      voyage.setVaultImpl(garbageAddress)
    ).to.be.revertedWithCustomError(voyage, 'InvalidVaultImpl');
  });

  it('should revert if passing an EOA as vault impl', async function () {
    const { voyage } = await setupTestSuite();
    const garbageAddress = ethers.utils.hexlify(ethers.utils.randomBytes(20));
    await expect(
      voyage.setVaultImpl(garbageAddress)
    ).to.be.revertedWithCustomError(voyage, 'InvalidVaultImpl');
  });

  it('should work if valid contract address', async function () {
    const { voyage, owner } = await setupTestSuite();
    const vaultImpl = await deployments.deploy('Vault2', {
      from: owner,
      contract: 'contracts/vault/Vault.sol:Vault',
    });
    await voyage.setVaultImpl(vaultImpl.address);
    expect(await voyage.getVaultImpl()).to.equal(vaultImpl.address);
  });

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

  it('Pass zero vault address should be revert', async function () {
    const { voyage, crab } = await setupTestSuite();
    await expect(
      voyage.withdrawNFT(ZERO_ADDRESS, crab.address, 1)
    ).to.be.revertedWithCustomError(voyage, 'InvalidVaultAddress');
  });

  it('Pass zero collection address should be revert', async function () {
    const { voyage, deployedVault } = await setupTestSuite();
    await expect(
      voyage.withdrawNFT(deployedVault, ZERO_ADDRESS, 1)
    ).to.be.revertedWithCustomError(voyage, 'InvalidCollectionAddress');
  });

  it('Pass zero currency address should be revert', async function () {
    const { voyage, alice, deployedVault } = await setupTestSuite();
    await expect(
      voyage.transferReserve(deployedVault, ZERO_ADDRESS, alice, 1)
    ).to.be.revertedWithCustomError(voyage, 'InvalidCurrencyAddress');
  });
});

import { toWad } from '@helpers/math';
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

  it('Pass a collection address to transferCurrency should be revert', async function () {
    const { voyage, deployedVault, crab, owner } = await setupTestSuite();
    await expect(
      voyage.transferCurrency(deployedVault, crab.address, owner, 1)
    ).to.be.revertedWithCustomError(voyage, 'InvalidCurrencyAddress');
  });

  it('Deposit eth should return correct weth value', async function () {
    const { voyage, deployedVault, owner, weth } = await setupTestSuite();
    const balanceBefore = await weth.balanceOf(deployedVault);
    const tx = {
      to: deployedVault,
      value: ethers.utils.parseEther('2'),
    };
    const signer = await ethers.getSigner(owner);
    const createReceipt = await signer.sendTransaction(tx);
    await createReceipt.wait();
    await voyage.depositWETH(deployedVault, toWad(1));
    const balanceAfter = await weth.balanceOf(deployedVault);
    expect(balanceAfter.sub(balanceBefore)).to.eq(toWad(1));
  });

  it('Withdraw weth should return correct value', async function () {
    const { voyage, deployedVault, owner, weth } = await setupTestSuite();
    const tx = {
      to: deployedVault,
      value: ethers.utils.parseEther('2'),
    };
    const signer = await ethers.getSigner(owner);
    const createReceipt = await signer.sendTransaction(tx);
    await createReceipt.wait();
    await voyage.depositWETH(deployedVault, toWad(1));
    const balanceBefore = await weth.balanceOf(deployedVault);
    await voyage.withdrawWETH(deployedVault, toWad(0.5));
    const balanceAfter = await weth.balanceOf(deployedVault);
    expect(balanceBefore.sub(balanceAfter)).to.eq(toWad(0.5));
  });
});

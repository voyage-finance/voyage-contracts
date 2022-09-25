import { toWad } from '@helpers/math';
import { expect } from 'chai';
import { randomBytes } from 'crypto';
import { deployments, ethers } from 'hardhat';
import {
  MAX_UINT256,
  REFUND_GAS_PRICE,
  REFUND_GAS_UNIT,
  ZERO_ADDRESS,
} from '../helpers/constants';
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

  it('Create vault should refund correct vaule', async function () {
    const { voyage, alice, owner, treasury } = await setupTestSuite();
    const salt = randomBytes(20);
    const computedVaultAddress = await voyage.computeCounterfactualAddress(
      alice,
      salt
    );
    console.log('computedVaultAddress: ', computedVaultAddress);
    // fund vault for first payment
    const tx = {
      to: computedVaultAddress,
      value: ethers.utils.parseEther('1000'),
    };
    const ownerSigner = await ethers.getSigner(owner);
    const createReceipt = await ownerSigner.sendTransaction(tx);
    await createReceipt.wait();
    const treasuryBalanceBefore = await ethers.provider.getBalance(treasury);
    console.log('treasuryBalanceBefore: ', treasuryBalanceBefore.toString());
    await voyage.createVault(alice, salt, REFUND_GAS_UNIT, REFUND_GAS_PRICE);
    const deployedVault = await voyage.getVault(alice);
    const treasuryBalanceAfter = await ethers.provider.getBalance(treasury);
    expect(treasuryBalanceAfter).to.eq(
      treasuryBalanceBefore.add(REFUND_GAS_UNIT * REFUND_GAS_PRICE)
    );
    console.log('treasuryBalanceAfter: ', treasuryBalanceAfter.toString());
  });

  it('Granted acount should be able to create vault', async function () {
    const { voyage, owner, alice } = await setupTestSuite();
    var abi = ['function createVault(address,bytes20,uint256,uint256)'];
    var iface = new ethers.utils.Interface(abi);
    var selector = iface.getSighash('createVault');

    await voyage.grantPermission(alice, voyage.address, selector);
    const salt = ethers.utils
      .keccak256(ethers.utils.toUtf8Bytes('alice@wonder.land'))
      .slice(0, 42);
    const computedVaultAddress = await voyage.computeCounterfactualAddress(
      alice,
      salt
    );
    const fundTx = {
      to: computedVaultAddress,
      value: REFUND_GAS_PRICE * REFUND_GAS_UNIT,
    };
    const ownerSigner = await ethers.getSigner(owner);
    const createReceipt = await ownerSigner.sendTransaction(fundTx);
    await createReceipt.wait();
    await voyage
      .connect(await ethers.getSigner(alice))
      .createVault(alice, salt, REFUND_GAS_UNIT, REFUND_GAS_PRICE);
    const deployedVault = await voyage.getVault(alice);
    console.log('deployed vault address for alice: ', deployedVault);
  });

  it('Pass zero vault address should be revert', async function () {
    const { voyage, crab } = await setupTestSuite();
    await expect(
      voyage.withdrawNFT(ZERO_ADDRESS, crab.address, 1)
    ).to.be.rejectedWith('InvalidVaultAddress');
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
    await voyage.wrapVaultETH(deployedVault, toWad(1));
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
    await voyage.wrapVaultETH(deployedVault, toWad(1));
    const balanceBefore = await weth.balanceOf(deployedVault);
    await voyage.unwrapVaultETH(deployedVault, toWad(0.5));
    const balanceAfter = await weth.balanceOf(deployedVault);
    expect(balanceBefore.sub(balanceAfter)).to.eq(toWad(0.5));
  });

  it('Withdraw a collateral NFT should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      deployedVault,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);
    await expect(
      voyage.withdrawNFT(deployedVault, crab.address, 1)
    ).to.be.revertedWithCustomError(voyage, 'InvalidWithdrawal');
  });

  it('Withdraw a non-collateral NFT should revert', async function () {
    const {
      crab,
      owner,
      voyage,
      deployedVault,
      priceOracle,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    await priceOracle.updateTwap(crab.address, toWad(10));
    const vault = await voyage.getVault(owner);
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);
    await voyage.repay(crab.address, 0, vault);
    await voyage.repay(crab.address, 0, vault);
    const onwerBefore = await crab.ownerOf(1);
    expect(onwerBefore).to.eq(deployedVault);
    await voyage.withdrawNFT(deployedVault, crab.address, 1);
    const onwerAfter = await crab.ownerOf(1);
    expect(onwerAfter).to.eq(owner);
  });

  it('Approve a valid marketplace should return correct vaule', async function () {
    const { voyage, deployedVault, marketPlace, weth } = await setupTestSuite();
    const allowanceBefore = await weth.allowance(
      deployedVault,
      marketPlace.address
    );
    expect(allowanceBefore).to.eq(0);
    await voyage.approveMarketplace(deployedVault, marketPlace.address, false);
    const allowanceAfter = await weth.allowance(
      deployedVault,
      marketPlace.address
    );
    expect(allowanceAfter).to.eq(MAX_UINT256);
  });

  it("Revoking marketplace's approval should return correct vaule", async function () {
    const { voyage, deployedVault, marketPlace, weth } = await setupTestSuite();
    const allowanceBefore = await weth.allowance(
      deployedVault,
      marketPlace.address
    );
    expect(allowanceBefore).to.eq(0);
    await voyage.approveMarketplace(deployedVault, marketPlace.address, true);
    const allowanceAfter = await weth.allowance(
      deployedVault,
      marketPlace.address
    );
    expect(allowanceAfter).to.eq(0);
  });

  it('Approve a invalid marketplace should revert', async function () {
    const { voyage, deployedVault } = await setupTestSuite();
    await expect(
      voyage.approveMarketplace(deployedVault, voyage.address, false)
    ).to.be.revertedWithCustomError(voyage, 'InvalidMarketplace');
  });
});

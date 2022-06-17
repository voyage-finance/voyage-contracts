import { ethers, getNamedAccounts } from 'hardhat';
import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault Signature', function () {
  it('Vault should recover correct address from signature', async function () {
    const { owner, tus, voyager } = await setupTestSuite();

    // Create a wallet to sign the message with
    let privateKey =
      '0x0123456789012345678901234567890123456789012345678901234567890123';
    let wallet = new ethers.Wallet(privateKey);

    console.log(wallet.address);
    let message = 'Hello World';
    let messageHash = ethers.utils.id(message);
    let messageHashBytes = ethers.utils.arrayify(messageHash);

    let flatSig = await wallet.signMessage(messageHashBytes);

    const salt = ethers.utils.formatBytes32String(
      (Math.random() + 1).toString(36).substring(7)
    );
    await voyager.createVault(owner, tus.address, salt);
    const vaultAddress = await voyager.getVault(owner);
    const Vault = await ethers.getContractFactory('Vault');
    const vault = Vault.attach(vaultAddress);
    const result = await vault.isValidSignature(messageHash, flatSig);
    console.log(result);
  });
});

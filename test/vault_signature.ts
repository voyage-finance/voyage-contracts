import { ethers, getNamedAccounts } from 'hardhat';
import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault Signature', function () {
  it('Vault should recover correct address from signature', async function () {
    const { owner, vault } = await setupTestSuite();

    // Create a wallet to sign the message with
    let privateKey =
      '0x0123456789012345678901234567890123456789012345678901234567890123';
    let wallet = new ethers.Wallet(privateKey);

    console.log(wallet.address);
    let message = 'Hello World';
    let messageHash = ethers.utils.id(message);
    let messageHashBytes = ethers.utils.arrayify(messageHash);

    const signer = await ethers.getSigner(owner);
    const flatSig = await signer.signMessage(messageHashBytes);
    const result = await vault.isValidSignature(messageHash, flatSig);
    expect(result).to.equal('0x1626ba7e');
  });
});

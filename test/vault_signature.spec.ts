import { ethers, getNamedAccounts } from 'hardhat';
import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault Signature', function () {
  it('Vault should recover correct address from signature', async function () {
    const { owner, voyage } = await setupTestSuite();
    const vaultAddress = await voyage.getVault(owner);
    const vault = await ethers.getContractAt('Vault', vaultAddress);
    const signer = await ethers.getSigner(owner);
    let message =
      'Welcome to OpenSea!\n\nClick to sign in and accept the OpenSea Terms of Service: https://opensea.io/tos\n\nThis request will not trigger a blockchain transaction or cost any gas fees.\n\nYour authentication status will reset after 24 hours.\n\nWallet address:\n0xad5792b1d998f607d3eeb2f357138a440b03f19f\n\nNonce:\naff63e58-1b2c-44a6-99c1-eb0fbc9dacab';
    const signature = await signer.signMessage(message);
    const rec = ethers.utils.verifyMessage(message, signature);
    expect(rec).to.equal(signer.address);
    const result = await vault.isValidSignature(
      ethers.utils.hashMessage(message),
      signature
    );
    expect(result).to.equal('0x1626ba7e');
  });
});

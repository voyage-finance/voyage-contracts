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
});

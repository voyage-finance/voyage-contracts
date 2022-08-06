import { expect } from 'chai';
import { ethers } from 'hardhat';
import { MarketplaceAdapterFacet } from 'typechain/MarketplaceAdapterFacet';
import { toWad } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Vault Adapter', function () {
  it('Vault adapter should validate correct bytes', async function () {
    const { tus, voyage, owner, purchaseData } = await setupTestSuite();
    const vaultAddr = await voyage.getVault(owner);
    const abiCoder = ethers.utils.defaultAbiCoder;

    const MarketplaceAdapterFacet = await ethers.getContractFactory(
      'MarketplaceAdapterFacet'
    );
    const marketplaceAdapterFacet = await MarketplaceAdapterFacet.attach(
      vaultAddr
    );
    await marketplaceAdapterFacet.validate(purchaseData);
  });
});

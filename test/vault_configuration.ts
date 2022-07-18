import { setupTestSuite } from '../helpers/setupTestSuite';
import { WAD } from '../helpers/constants';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Vault margin configuration', async () => {
  it('should always use global margin by default', async () => {
    const { voyage, tus, owner } = await setupTestSuite();
    const globalMargin = {
      min: 0,
      max: 10_000,
      marginRequirement: 1000,
    };
    await voyage.setMarginParams(
      tus.address,
      globalMargin.min,
      globalMargin.max,
      globalMargin.marginRequirement
    );
    const vault = await voyage.getVault(owner);

    let [globalMin, globalMax, marginRequirement] =
      await voyage.getMarginConfiguration(tus.address);
    let [vaultMin, vaultMax, vaultMarginRequirement] =
      await voyage.getVaultConfig(tus.address, vault);

    expect(globalMin).to.equal(vaultMin);
    expect(globalMax).to.equal(vaultMax);
    expect(marginRequirement).to.equal(vaultMarginRequirement);
  });

  it('should use vault config if overridden', async () => {
    const { voyage, tus, owner } = await setupTestSuite();
    const globalMargin = {
      min: 0,
      max: 10_000,
      marginRequirement: 1000,
    };
    await voyage.setMarginParams(
      tus.address,
      globalMargin.min,
      globalMargin.max,
      globalMargin.marginRequirement
    );

    const vault = await voyage.getVault(owner);
    const vaultMargin = {
      min: 100,
      max: 100_000,
      marginRequirement: 1000,
    };

    const [globalMin, globalMax, marginRequirement] =
      await voyage.getMarginConfiguration(tus.address);
    expect(globalMin).to.equal(
      ethers.BigNumber.from(globalMargin.min).mul(WAD)
    );
    expect(globalMax).to.equal(
      ethers.BigNumber.from(globalMargin.max).mul(WAD)
    );
    expect(marginRequirement).to.equal(globalMargin.marginRequirement);

    await expect(
      voyage.overrideMarginConfig(
        tus.address,
        vault,
        vaultMargin.min,
        vaultMargin.max,
        vaultMargin.marginRequirement
      )
    )
      .to.emit(voyage, 'VaultMarginParametersUpdated')
      .withArgs(
        tus.address,
        vault,
        vaultMargin.min,
        vaultMargin.max,
        vaultMargin.marginRequirement
      );
    const [vaultMin, vaultMax, vaultMarginRequirement, overridden] =
      await voyage.getVaultConfig(tus.address, vault);
    expect(vaultMin).to.equal(ethers.BigNumber.from(vaultMargin.min).mul(WAD));
    expect(vaultMax).to.equal(ethers.BigNumber.from(vaultMargin.max).mul(WAD));
    expect(vaultMarginRequirement).to.equal(vaultMargin.marginRequirement);
    expect(overridden).to.be.true;
  });
});

import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { RAY, toWadValue, WAD } from '../helpers/math';
import BigNumber from 'bignumber.js';

describe('Liquidate', function () {
  it('Liquidate a invalid debt should revert', async function () {
    const {
      owner,
      juniorDepositToken,
      seniorDepositToken,
      vault,
      tus,
      voyage,
    } = await setupTestSuite();

    const depositAmount = toWadValue(100);
    const maxMargin = toWadValue(1000);
    await voyage.setMaxMargin(tus.address, maxMargin);
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const marginRequirement = new BigNumber(0.1).multipliedBy(RAY).toFixed();
    await voyage.setMarginRequirement(tus.address, marginRequirement);

    await voyage.depositMargin(vault.address, tus.address, depositAmount);
    const borrowAmount = toWadValue(10);
    await voyage.borrow(tus.address, borrowAmount, vault.address);

    // repay the first draw down
    await voyage.repay(tus.address, 0, vault.address);

    // try to liquidate
    await expect(
      voyage.liquidate(tus.address, vault.address, 0)
    ).to.be.revertedWith('InvalidLiquidate()');
  });

  it('Invalid floor price should revert', async function () {
    const {
      owner,
      juniorDepositToken,
      seniorDepositToken,
      vault,
      tus,
      voyage,
    } = await setupTestSuite();

    const depositAmount = toWadValue(100);
    const maxMargin = toWadValue(1000);
    await voyage.setMaxMargin(tus.address, maxMargin);
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const marginRequirement = new BigNumber(0.1).multipliedBy(RAY).toFixed();
    await voyage.setMarginRequirement(tus.address, marginRequirement);

    await voyage.depositMargin(vault.address, tus.address, depositAmount);
    const borrowAmount = toWadValue(10);
    await voyage.borrow(tus.address, borrowAmount, vault.address);
    // increase 51 days
    const days = 51 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [days]);
    await ethers.provider.send('evm_mine', []);

    await expect(
      voyage.liquidate(tus.address, vault.address, 0)
    ).to.be.revertedWith('InvalidFloorPrice()');
  });

  it('Valid liquidate with nft should return correct value', async function () {
    const {
      owner,
      juniorDepositToken,
      seniorDepositToken,
      vault,
      tus,
      voyage,
      priceOracle,
      crab,
    } = await setupTestSuite();

    const depositAmount = toWadValue(100);
    const maxMargin = toWadValue(1000);
    await voyage.setMaxMargin(tus.address, maxMargin);
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const marginRequirement = new BigNumber(0.1).multipliedBy(RAY).toFixed();
    await voyage.setMarginRequirement(tus.address, marginRequirement);
    await voyage.depositMargin(vault.address, tus.address, depositAmount);
    const borrowAmount = toWadValue(100);
    await voyage.borrow(tus.address, borrowAmount, vault.address);

    await crab.safeMint(vault.address, 1);

    // update oracle price
    await priceOracle.updateCumulative(crab.address, '10000000000000000000');
    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);
    await priceOracle.updateCumulative(crab.address, '10000000000000000000');
    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);
    await priceOracle.updateCumulative(crab.address, '10000000000000000000');
    await priceOracle.updateAssetPrice(crab.address);

    // increase 51 days
    const days = 51 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [days]);
    await ethers.provider.send('evm_mine', []);

    const tx = await voyage.liquidate(tus.address, vault.address, 0);

    const receipt = await tx.wait();
    if (receipt.events !== undefined) {
      for (const event of receipt.events) {
        if (event.event == 'Liquidate') {
          console.log(event.args);
        }
      }
    }

    await expect(await crab.ownerOf(1)).to.equal(owner);
  });
});

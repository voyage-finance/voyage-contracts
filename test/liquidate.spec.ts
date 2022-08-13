import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Tus } from 'typechain/Tus';
import { toWad } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

describe('Liquidate', function () {
  it('Liquidate a invalid debt should revert', async function () {
    const {
      owner,
      priceOracle,
      crab,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.deposit(crab.address, 0, depositAmount);
    await voyage.deposit(crab.address, 1, depositAmount);

    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      '1',
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );

    // repay the first draw down
    await voyage.repay(crab.address, 0, vault);

    // try to liquidate
    await expect(
      voyage.liquidate(crab.address, vault, 0)
    ).to.be.revertedWithCustomError(voyage, 'InvalidLiquidate');
  });

  it('Invalid floor price should revert', async function () {
    const {
      owner,
      priceOracle,
      crab,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.deposit(crab.address, 0, depositAmount);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      '1',
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await increase(51);

    // try to liquidate
    await priceOracle.updateTwap(crab.address, toWad(0));
    await expect(
      voyage.liquidate(crab.address, vault, 1)
    ).to.be.revertedWithCustomError(voyage, 'InvalidFloorPrice');
  });

  it('Valid liquidate with nft should return correct value', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    // epoch + grace period
    await increase(41);
    await voyage.liquidate(crab.address, vault, 0);
    await expect(await crab.ownerOf(1)).to.equal(owner);
  });

  it('Valid liquidate with remaining funds should refund to the vault', async function () {
    const {
      owner,
      voyage,
      priceOracle,
      crab,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
    } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    await priceOracle.updateTwap(crab.address, toWad(10));
    await voyage.buyNow(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare
    );
    await crab.safeMint(vault, 1);

    // epoch + grace period
    await increase(41);
    await priceOracle.updateTwap(crab.address, toWad(100));
    await voyage.liquidate(crab.address, vault, 0);
    await expect(await crab.ownerOf(1)).to.equal(owner);
    const refundedAmount = await weth.balanceOf(vault);
    console.log('refunded amount: ', refundedAmount.toString());
    await expect(refundedAmount).to.be.gt(toWad(0));
  });

  async function increase(n: number) {
    const days = n * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [days]);
    await ethers.provider.send('evm_mine', []);
  }

  function log(receipt: any) {
    if (receipt.events !== undefined) {
      for (const event of receipt.events) {
        if (event.event == 'Liquidate') {
          console.log('Event Liquidate: ');
          const ret = new Map<string, string>();
          if (event.args) {
            ret.set('liquidator', event.args[0]);
            ret.set('vault', event.args[1]);
            ret.set('asset', event.args[2]);
            ret.set('draw down id', event.args[3].toString());
            ret.set('repayment id', event.args[4].toString());
            ret.set('debt', event.args[5].toString());
            ret.set('margin', event.args[6].toString());
            ret.set('collateral', event.args[7].toString());
            ret.set('junior', event.args[8].toString());
            ret.set('write down', event.args[9].toString());
            console.table(ret);
          }
        }
      }
    }
  }
});

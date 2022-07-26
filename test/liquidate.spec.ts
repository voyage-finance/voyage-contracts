import { expect } from 'chai';
import { ethers } from 'hardhat';
import { toWad } from '../helpers/math';
import { setupTestSuite } from '../helpers/setupTestSuite';

const liquidationBonus = ethers.BigNumber.from(10500);
const maxMargin = 1000;
const marginRequirement = 0.1 * 1e4;

describe('Liquidate', function () {
  it('Liquidate a invalid debt should revert', async function () {
    const { owner, tus, voyage } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.deposit(tus.address, 0, depositAmount);
    await voyage.deposit(tus.address, 1, depositAmount);

    await voyage.depositMargin(vault, tus.address, depositAmount);
    const borrowAmount = toWad(10);
    await voyage.borrow(tus.address, borrowAmount, vault);

    // repay the first draw down
    await voyage.repay(tus.address, 0, vault);

    // try to liquidate
    await expect(voyage.liquidate(tus.address, vault, 0)).to.be.revertedWith(
      'InvalidLiquidate()'
    );
  });

  it('Invalid floor price should revert', async function () {
    const { owner, tus, voyage } = await setupTestSuite();
    await voyage.setLiquidationBonus(tus.address, liquidationBonus);
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(100);
    await voyage.setMarginParams(tus.address, 0, maxMargin, marginRequirement);
    await voyage.deposit(tus.address, 0, depositAmount);
    await voyage.deposit(tus.address, 1, depositAmount);
    await voyage.depositMargin(vault, tus.address, depositAmount);
    const borrowAmount = toWad(10);
    await voyage.borrow(tus.address, borrowAmount, vault);
    // increase 51 days
    const days = 51 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [days]);
    await ethers.provider.send('evm_mine', []);

    await expect(voyage.liquidate(tus.address, vault, 0)).to.be.revertedWith(
      'InvalidFloorPrice()'
    );
  });

  it('Valid liquidate with nft should return correct value', async function () {
    const { owner, tus, voyage, priceOracle, crab } = await setupTestSuite();
    const vault = await voyage.getVault(owner);

    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    const margin = toWad(20);
    await voyage.deposit(tus.address, 0, juniorDeposit);
    await voyage.deposit(tus.address, 1, depositAmount);
    await voyage.depositMargin(vault, tus.address, margin);
    const borrowAmount = toWad(120);
    await voyage.borrow(tus.address, borrowAmount, vault);

    await crab.safeMint(vault, 1);

    // update oracle price
    await priceOracle.updateCumulative(crab.address, '10000000000000000000');
    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);
    await priceOracle.updateCumulative(crab.address, '10000000000000000000');
    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine', []);
    await priceOracle.updateCumulative(crab.address, '10000000000000000000');
    await priceOracle.updateTwap(crab.address);

    // increase 51 days
    await increase(51);
    const tx = await voyage.liquidate(tus.address, vault, 0);

    const receipt = await tx.wait();
    log(receipt);

    await expect(await crab.ownerOf(1)).to.equal(owner);

    // increase 51 days again
    await increase(51);
    const tx2 = await voyage.liquidate(tus.address, vault, 0);

    const receipt2 = await tx2.wait();
    log(receipt2);

    // increase 51 days again
    await increase(51);
    const tx3 = await voyage.liquidate(tus.address, vault, 0);

    const receipt3 = await tx3.wait();
    log(receipt3);
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

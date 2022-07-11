import { expect } from 'chai';
import { ethers, getNamedAccounts } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

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

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMaxMargin(tus.address, '1000000000000000000000');
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyage.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyage.borrow(tus.address, '10000000000000000000', vault.address);

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

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMaxMargin(tus.address, '1000000000000000000000');
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyage.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyage.borrow(tus.address, '10000000000000000000', vault.address);

    // increase 51 days
    const days = 51 * 24 * 60 * 60;
    await ethers.provider.send('evm_increaseTime', [days]);
    await ethers.provider.send('evm_mine', []);

    await expect(
      voyage.liquidate(tus.address, vault.address, 0)
    ).to.be.revertedWith('InvalidFloorPrice()');
  });

  it.only('Valid liquidate should return correct value', async function () {
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

    // 100
    const depositAmount = '100000000000000000000';
    await voyage.setMaxMargin(tus.address, '1000000000000000000000');
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    const seniorLiquidity = await tus.balanceOf(seniorDepositToken.address);
    const juniorLiquidity = await tus.balanceOf(juniorDepositToken.address);
    console.log('senior liquidity: ', seniorLiquidity.toString());
    console.log('junior liquidity: ', juniorLiquidity.toString());
    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyage.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyage.borrow(tus.address, '10000000000000000000', vault.address);

    // update
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

    await voyage.liquidate(tus.address, vault.address, 0);
  });
});

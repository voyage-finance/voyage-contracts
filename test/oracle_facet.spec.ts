import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  setupTestSuite,
  setupTestTwapTolerance,
} from '../helpers/setupTestSuite';
import { toWad } from '@helpers/math';
import { BigNumber } from 'ethers';

describe('Oracle Facet', function () {
  // make non-strict timestamp
  const currentTime = Math.floor(Date.now() / 1000) - 20;
  it('Buy with incorrect message id => revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRareWithWETH,
      marketPlace,
      weth,
      twapSigner,
    } = await setupTestSuite();
    await voyage.deposit(crab.address, 0, toWad(50));
    await voyage.deposit(crab.address, 1, toWad(120));
    const message = await setupTestTwapTolerance(
      twapSigner,
      crab.address,
      voyage,
      weth.address,
      currentTime,
      10
    );
    message.id =
      '0x0000000000000000000000000000000000000000000000000000000000000000';

    const vault = await voyage.getVault(owner);

    // check vault balance
    const ethBalance = await ethers.provider.getBalance(vault);
    const wethBalance = await weth.balanceOf(vault);

    // transfer eth out
    await voyage.transferETH(vault, owner, ethBalance);
    await voyage.transferCurrency(vault, weth.address, owner, wethBalance);

    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRareWithWETH,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTwapMessageId');
  });

  it('Buy with 0 max twap staleness and with future timestamp => revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
      twapSigner,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const vault = await voyage.getVault(owner);
    // 1.0 Buy with 0 max twap staleness
    const twapStaleness = 0;
    // 1.1 set maxTwapStaleness to 0
    await voyage.setMaxTwapStaleness(crab.address, twapStaleness);
    await expect(await voyage.getMaxTwapStaleness(crab.address)).to.be.equal(
      BigNumber.from(twapStaleness)
    );
    // 1.2 set timestamp to past, trigger condition (message.timestamp + validFor < block.timestamp)
    const message = await setupTestTwapTolerance(
      twapSigner,
      crab.address,
      voyage,
      weth.address,
      currentTime - 1000
    );
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTwapTimestamp');

    // 2.0 Buy with future timestamp
    await voyage.setMaxTwapStaleness(crab.address, 3600);
    // 2.1 set timestamp to future, to trigger cond (message.timestamp > block.timestamp)
    message.timestamp = currentTime + 1000;
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTwapTimestamp');
  });

  it('Buy with just staled floor price => revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
      twapSigner,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const vault = await voyage.getVault(owner);
    // 1.0 set twapStaleness to 100
    const twapStaleness = 100;
    await voyage.setMaxTwapStaleness(crab.address, twapStaleness);
    await expect(await voyage.getMaxTwapStaleness(crab.address)).to.be.equal(
      BigNumber.from(twapStaleness)
    );
    // 1.1 set message timestamp to currentTime
    const message = await setupTestTwapTolerance(
      twapSigner,
      crab.address,
      voyage,
      weth.address,
      currentTime
    );
    // 1.2 block.timestamp to currentTimestamp + twapStaleness
    await ethers.provider.send('evm_mine', [currentTime + twapStaleness - 1]);
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTwapTimestamp');
  });

  it('Buy with outdated floor price => revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
      twapSigner,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const vault = await voyage.getVault(owner);
    // 1.0 set twapStaleness to 100
    const twapStaleness = 3600;
    await voyage.setMaxTwapStaleness(crab.address, twapStaleness);
    await expect(await voyage.getMaxTwapStaleness(crab.address)).to.be.equal(
      BigNumber.from(twapStaleness)
    );
    // 1.1 set message timestamp to currentTime
    const message = await setupTestTwapTolerance(
      twapSigner,
      crab.address,
      voyage,
      weth.address,
      currentTime - twapStaleness
    );
    // 1.2 block.timestamp to currentTimestamp + twapStaleness
    await ethers.provider.send('evm_mine', [currentTime + 2 * twapStaleness]);
    await expect(
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      )
    ).to.be.revertedWithCustomError(voyage, 'InvalidTwapTimestamp');
  });

  it('Buy with invalid signature => revert', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
      twapSigner,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const vault = await voyage.getVault(owner);
    console.log(
      'getMaxTwapStaleness: ',
      (await voyage.getMaxTwapStaleness(crab.address)).toString()
    );

    const message = await setupTestTwapTolerance(
      twapSigner,
      crab.address,
      voyage,
      weth.address,
      currentTime
    );
    const correctSignature = message.signature;
    // 1.0 check list of invalid signatures
    for (const signature of [
      '0x',
      '0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
      '0xabcd',
    ]) {
      message.signature = signature;
      await expect(
        voyage.buyNowV2(
          crab.address,
          1,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRare,
          message
        )
      ).to.be.revertedWithCustomError(voyage, 'InvalidTwapMessageSignature');
    }
    // 2.0 set correct signer => pass
    message.signature = correctSignature;
    await voyage.buyNowV2(
      crab.address,
      1,
      vault,
      marketPlace.address,
      purchaseDataFromLooksRare,
      message
    );
  });

  it('sign with different signers', async function () {
    const {
      crab,
      owner,
      voyage,
      purchaseDataFromLooksRare,
      marketPlace,
      weth,
      twapSigner,
      alice,
      bob,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    const vault = await voyage.getVault(owner);

    let message;
    // 1.0 sign with incorrect signers (where oracleSigner=twapSigner) => revert
    for (const signer of [alice, bob, owner]) {
      console.log('incorrect-signer: ', signer);
      message = await setupTestTwapTolerance(
        signer,
        crab.address,
        voyage,
        weth.address,
        currentTime
      );
      await expect(
        voyage.buyNowV2(
          crab.address,
          1,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRare,
          message
        )
      ).to.be.revertedWithCustomError(voyage, 'InvalidTwapSigner');
    }
    // 2.0 set signers and check => pass
    const signers = [alice, bob, owner, twapSigner];
    for (const signer of signers) {
      console.log('correct-signer: ', signer);
      await voyage.setOracleSigner(signer);
      await expect(await voyage.getOracleSigner()).to.be.equal(signer);
      message = await setupTestTwapTolerance(
        signer,
        crab.address,
        voyage,
        weth.address,
        currentTime
      );
      voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      );
    }
  });

  it('Buy with (invalid/valid) principals/twap', async function () {
    const {
      crab,
      owner,
      voyage,
      marketPlace,
      purchaseDataFromLooksRare,
      weth,
      twapSigner,
    } = await setupTestSuite();
    const depositAmount = toWad(120);
    const juniorDeposit = toWad(50);
    await voyage.deposit(crab.address, 0, juniorDeposit);
    await voyage.deposit(crab.address, 1, depositAmount);
    let message;
    const vault = await voyage.getVault(owner);

    // 1.0 invalid prices check
    let twapTolerance = 2000;
    // 1.1 set twap tollerance to 20%
    await voyage.setTwapTolerance(crab.address, twapTolerance);
    expect(await voyage.getTwapTolerance(crab.address)).to.be.equal(
      twapTolerance
    );
    // 1.2 should revert
    for (const twap of [0.00001, 1, 5, 6.6667, 8.33]) {
      // price of asset is 10, then we will change twap dynamically
      message = await setupTestTwapTolerance(
        twapSigner,
        crab.address,
        voyage,
        weth.address,
        currentTime,
        twap
      );
      await expect(
        voyage.buyNowV2(
          crab.address,
          1,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRare,
          message
        )
      ).to.be.revertedWithCustomError(voyage, 'ExceedsFloorPrice');
    }
    // 1.3 should pass
    for (const twap of [8.34, 9, 10, 100000000]) {
      // price of asset is 10, then we will change twap dynamically
      message = await setupTestTwapTolerance(
        twapSigner,
        crab.address,
        voyage,
        weth.address,
        currentTime,
        twap
      );
      await voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      );
    }

    // 2.1 set twap tollerance to 0%
    twapTolerance = 0;
    await voyage.setTwapTolerance(crab.address, twapTolerance);
    expect(await voyage.getTwapTolerance(crab.address)).to.be.equal(
      twapTolerance
    );
    // 2.2 should revert
    for (const twap of [7, 8.88, 9.9999]) {
      // price of asset is 10, then we will change twap dynamically
      message = await setupTestTwapTolerance(
        twapSigner,
        crab.address,
        voyage,
        weth.address,
        currentTime,
        twap
      );
      await expect(
        voyage.buyNowV2(
          crab.address,
          1,
          vault,
          marketPlace.address,
          purchaseDataFromLooksRare,
          message
        )
      ).to.be.revertedWithCustomError(voyage, 'ExceedsFloorPrice');
    }

    // 2.3 should pass
    for (const twap of [10, 11, 1222222222]) {
      // price of asset is 10, then we will change twap dynamically
      message = await setupTestTwapTolerance(
        twapSigner,
        crab.address,
        voyage,
        weth.address,
        currentTime,
        twap
      );
      await voyage.buyNowV2(
        crab.address,
        1,
        vault,
        marketPlace.address,
        purchaseDataFromLooksRare,
        message
      );
    }
  });
});

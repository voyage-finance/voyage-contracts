import { expect } from 'chai';
import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { MAX_UINT_256 } from '../helpers/math';

describe('External call', function () {
  it('External call should return correct value', async function () {
    const { owner, alice, tus, crab, marketPlace, voyager, vault } =
      await setupTestSuite();
    // mint one crab to alice
    await crab.safeMint(alice, 1);
    await crab.safeMint(alice, 2);
    await crab
      .connect(await ethers.getSigner(alice))
      .setApprovalForAll(marketPlace.address, true);
    await marketPlace
      .connect(await ethers.getSigner(alice))
      .makeSellOrder(1, '10000000000000000000');
    await marketPlace
      .connect(await ethers.getSigner(alice))
      .makeSellOrder(2, '10000000000000000000');
    const orderInfo = await marketPlace.sellOrders(1);
    console.log('order info: ', orderInfo);
    await tus.transfer(vault.address, '1000000000000000000000');
    const call = [
      {
        erc721Addr: crab.address,
        target: tus.address,
        callData: tus.interface.encodeFunctionData('approve(address,uint256)', [
          marketPlace.address,
          MAX_UINT_256,
        ]),
      },
      {
        erc721Addr: crab.address,
        target: marketPlace.address,
        callData: marketPlace.interface.encodeFunctionData('buyCard(uint256)', [
          '1',
        ]),
      },
    ];

    const invokeRet = await vault.callExternal(call);
    console.log(invokeRet);
    const ownerOfOne = await crab.ownerOf(2);
    expect(ownerOfOne).to.equal(vault.address);
  });
});

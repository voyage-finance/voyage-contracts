import { ethers, getNamedAccounts } from 'hardhat';
import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { MAX_UINT_256 } from '../helpers/math';

describe('Vault', function () {
  it('Full process', async function () {
    const { alice, vault, tus, voyager, crab, marketPlace } =
      await setupTestSuite();
    const { owner } = await getNamedAccounts();
    const depositAmount = '100000000000000000000';
    await voyager.setMaxMargin(tus.address, '1000000000000000000000');
    await voyager.deposit(tus.address, 0, depositAmount, owner);
    await voyager.deposit(tus.address, 1, depositAmount, owner);
    await voyager.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyager.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyager.borrow(tus.address, '100000000000000000000', vault.address);
    const escrowAddr = await vault.creditEscrow(tus.address);
    console.log('reserve escrow: ', escrowAddr);
    const vaultBalance = await tus.balanceOf(escrowAddr);
    console.log('vault balance: ', vaultBalance.toString());

    await crab.safeMint(alice, 1);
    await crab
      .connect(await ethers.getSigner(alice))
      .setApprovalForAll(marketPlace.address, true);
    await marketPlace
      .connect(await ethers.getSigner(alice))
      .makeSellOrder(1, '20000000000000000000');
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
          '0',
        ]),
      },
    ];
    await vault.callExternal(call);

    const vaultBalanceAfter = await tus.balanceOf(vault.address);
    console.log('vault balance after buying: ', vaultBalanceAfter.toString());

    const vaultData = await voyager.getVaultData(vault.address, tus.address);
    console.log('draw down list: ', vaultData.drawDownList.toString());

    const drawDownDetail = await voyager.getDrawDownDetail(
      vault.address,
      tus.address,
      0
    );
    console.log('draw down 0 detail: ', drawDownDetail.toString());

    await expect(
      vault.withdrawNFT(tus.address, crab.address, 1)
    ).to.be.revertedWith('Vault: invalid withdrawal');

    await voyager.repay(tus.address, 0, vault.address);
    await voyager.repay(tus.address, 0, vault.address);
    await voyager.repay(tus.address, 0, vault.address);

    const ownerBefore = await crab.ownerOf(1);
    expect(ownerBefore).to.equal(vault.address);

    await vault.withdrawNFT(tus.address, crab.address, 1);

    const ownerAfter = await crab.ownerOf(1);
    expect(ownerAfter).to.equal(owner);
  });
});

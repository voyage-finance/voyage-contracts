import { ethers, getNamedAccounts } from 'hardhat';
import { expect } from 'chai';
import { setupTestSuite } from '../helpers/setupTestSuite';
import { MAX_UINT_256 } from '../helpers/math';

describe('Vault adapter', function () {
  it('Call buy nft should return correct value', async function () {
    const { alice, vault, tus, voyage, crab, marketPlace } =
      await setupTestSuite();
    const { owner } = await getNamedAccounts();
    const depositAmount = '100000000000000000000';
    await voyage.setMaxMargin(tus.address, '1000000000000000000000');
    await voyage.deposit(tus.address, 0, depositAmount, owner);
    await voyage.deposit(tus.address, 1, depositAmount, owner);
    await voyage.setMarginRequirement(
      tus.address,
      '100000000000000000000000000'
    ); // 0.1

    await voyage.depositMargin(
      vault.address,
      tus.address,
      '100000000000000000000'
    );
    await voyage.borrow(tus.address, '100000000000000000000', vault.address);
    const escrowAddr = await voyage.getVaultEscrowAddr(owner, tus.address);
    console.log('reserve escrow: ', escrowAddr[0]);
    const vaultBalance = await tus.balanceOf(escrowAddr[0]);
    console.log('vault balance: ', vaultBalance.toString());

    await crab.safeMint(alice, 1);
    await crab
      .connect(await ethers.getSigner(alice))
      .setApprovalForAll(marketPlace.address, true);
    await marketPlace
      .connect(await ethers.getSigner(alice))
      .makeSellOrder(1, '20000000000000000000');
    await voyage.approveBuy(crab.address, 0, vault.address);
  });
});

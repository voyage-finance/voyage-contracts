import { ethers } from 'hardhat';
import { setupTestSuite } from '../helpers/setupTestSuite';

const max = 1000;
const requirement = 0.1 * 1e4;
describe('Vault adapter', function () {
  it('Call buy nft should return correct value', async function () {
    const { alice, tus, voyage, crab, marketPlace, owner } =
      await setupTestSuite();
    const vault = await voyage.getVault(owner);
    const depositAmount = '100000000000000000000';
    await voyage.setMarginParams(tus.address, 0, max, requirement);
    await voyage.deposit(tus.address, 0, depositAmount);
    await voyage.deposit(tus.address, 1, depositAmount);
    await voyage.depositMargin(vault, tus.address, '100000000000000000000');
    await voyage.borrow(tus.address, '100000000000000000000', vault);
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
    await voyage.approveBuy(crab.address, 0, vault);
  });
});

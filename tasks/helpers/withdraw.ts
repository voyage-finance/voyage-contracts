import { task } from 'hardhat/config';
import { formatWad, MAX_UINT_256 } from '@helpers/math';
import { Voyage } from '@contracts';

enum Tranche {
  Junior,
  Senior,
}

task('dev:withdraw', 'Withdraws from the specified pool.')
  .addOptionalParam('reserve', 'The reserve from which to withdraw.')
  .addOptionalParam('tranche', 'The tranche to withdraw from.')
  .addOptionalParam('amount', 'The amount to be withdrawn in ETH.')
  .setAction(async (params, hre) => {
    const { ethers, getNamedAccounts } = hre;
    const { owner } = await getNamedAccounts();
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const collection = await ethers.getContract('Crab');
    const {
      reserve = collection.address,
      tranche = Tranche.Senior,
      amount,
    } = params;
    const [sr, jr] = await voyage.getDepositTokens(reserve);

    const srVToken = await ethers.getContractAt('SeniorDepositToken', sr);
    const srVTokenAllowance = await srVToken.allowance(owner, voyage.address);
    if (srVTokenAllowance.lt(MAX_UINT_256)) {
      const tx = await srVToken.approve(voyage.address, MAX_UINT_256);
      await tx.wait();
    }

    const jrVToken = await ethers.getContractAt('JuniorDepositToken', jr);
    const jrVTokenAllowance = await jrVToken.allowance(owner, voyage.address);
    console.log('jrVTokenAllowance: ', jrVTokenAllowance);
    if (jrVTokenAllowance.lt(MAX_UINT_256)) {
      const tx = await jrVToken.approve(voyage.address, MAX_UINT_256);
      await tx.wait();
    }
    const balance = await voyage.balance(reserve, owner, tranche);
    const withdrawAmount = amount ? ethers.utils.parseEther(amount) : balance;
    const signer = await ethers.getSigner(owner);
    const tx = await voyage.withdraw(reserve, tranche, withdrawAmount);
    await tx.wait();
    console.log(
      `Withdrew ${formatWad(withdrawAmount)} from tranche ${tranche}`
    );
  });

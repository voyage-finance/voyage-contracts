import { JuniorDepositToken, SeniorDepositToken, Voyage } from '@contracts';
import { ethers } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';

async function main() {
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const crab = await ethers.getContract('Crab');
  const [senior, junior] = await voyage.getDepositTokens(crab.address);
  const seniorDepositToken = await ethers.getContractAt<SeniorDepositToken>(
    'SeniorDepositToken',
    senior
  );
  const juniorDepositToken = await ethers.getContractAt<JuniorDepositToken>(
    'JuniorDepositToken',
    junior
  );
  await seniorDepositToken
    .approve(voyage.address, MAX_UINT_256)
    .then((tx) => tx.wait())
    .then(() => juniorDepositToken.approve(voyage.address, MAX_UINT_256))
    .then((tx) => tx.wait());

  await voyage.withdraw(crab.address, '1', '100');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

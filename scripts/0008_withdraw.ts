import { deployments, ethers, getNamedAccounts } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';
import { JuniorDepositToken, SeniorDepositToken, Voyage } from '@contracts';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const tus = await deployments.get('Tus');
  const [senior, junior] = await voyage.getDepositTokens(tus.address);
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

  await voyage.withdraw(tus.address, '1', '10000000000000000000');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

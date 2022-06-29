import { deployments, ethers, getNamedAccounts } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';
import { JuniorDepositToken, SeniorDepositToken, Voyager } from '@contracts';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract<Voyager>('Voyager');
  const tus = await deployments.get('Tus');
  const [senior, junior] = await voyager.getDepositTokens(tus.address);
  const seniorDepositToken = await ethers.getContractAt<SeniorDepositToken>(
    'SeniorDepositToken',
    senior
  );
  const juniorDepositToken = await ethers.getContractAt<JuniorDepositToken>(
    'JuniorDepositToken',
    junior
  );
  await seniorDepositToken
    .approve(voyager.address, MAX_UINT_256)
    .then((tx) => tx.wait())
    .then(() => juniorDepositToken.approve(voyager.address, MAX_UINT_256))
    .then((tx) => tx.wait());

  await voyager.withdraw(tus.address, '1', '10000000000000000000', owner);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

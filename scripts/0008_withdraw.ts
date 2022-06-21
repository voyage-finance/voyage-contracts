import { deployments, ethers, getNamedAccounts } from 'hardhat';
import { MAX_UINT_256 } from '../helpers/math';
import { BaseDepositToken, Voyager } from '@contracts';

async function main() {
  const { owner } = await getNamedAccounts();
  const voyager = await ethers.getContract<Voyager>('Voyager');
  const tus = await deployments.get('Tus');
  const seniorDepositToken = await ethers.getContract<BaseDepositToken>(
    'SeniorDepositToken'
  );
  const juniorDepositToken = await ethers.getContract<BaseDepositToken>(
    'JuniorDepositToken'
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

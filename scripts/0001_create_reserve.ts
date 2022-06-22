import { Voyager } from '@contracts';
import { ContractTransaction } from 'ethers';
import { ethers, deployments } from 'hardhat';

const getAddress = (contract: string) =>
  deployments.get(contract).then(({ address }) => address);

async function main() {
  const treasureUnderSea = await getAddress('Tus');
  const juniorDepositToken = await getAddress('JuniorDepositToken');
  const seniorDepositToken = await getAddress('SeniorDepositToken');
  const loanStrategy = await getAddress('DefaultLoanStrategy');
  const interestStrategy = await getAddress(
    'DefaultReserveInterestRateStrategy'
  );
  const voyager = await ethers.getContract<Voyager>('Voyager');
  const tus = await ethers.getContract('Tus');

  const [initialized, activated] = await voyager.getReserveStatus(tus.address);
  let tx: ContractTransaction;
  if (!initialized) {
    tx = await voyager.initReserve(
      treasureUnderSea,
      juniorDepositToken,
      seniorDepositToken,
      interestStrategy,
      loanStrategy,
      '500000000000000000000000000'
    );
    await tx.wait();
  }
  if (!activated) {
    tx = await voyager.activateReserve(tus.address);
    await tx.wait();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
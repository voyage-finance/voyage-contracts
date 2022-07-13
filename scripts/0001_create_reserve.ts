import { Voyage } from '@contracts';
import { ContractTransaction } from 'ethers';
import { ethers, deployments } from 'hardhat';

const getAddress = (contract: string) =>
  deployments.get(contract).then(({ address }) => address);

async function main() {
  const treasureUnderSea = await getAddress('Tus');
  const loanStrategy = await getAddress('DefaultLoanStrategy');
  const interestStrategy = await getAddress(
    'DefaultReserveInterestRateStrategy'
  );
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const tus = await ethers.getContract('Tus');
  const crab = await ethers.getContract('Crab');
  const priceOracle = await ethers.getContract('PriceOracle');

  const [initialized, activated] = await voyage.getReserveStatus(tus.address);
  let tx: ContractTransaction;
  if (!initialized) {
    tx = await voyage.initReserve(
      treasureUnderSea,
      interestStrategy,
      loanStrategy,
      '500000000000000000000000000',
      priceOracle.address,
      crab.address
    );
    await tx.wait();
  }
  if (!activated) {
    tx = await voyage.activateReserve(tus.address);
    await tx.wait();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

import { Voyage } from '@contracts';
import { ContractTransaction } from 'ethers';
import { ethers, deployments } from 'hardhat';

const getAddress = (contract: string) =>
  deployments.get(contract).then(({ address }) => address);

async function main() {
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
    await voyage
      .initReserve(
        crab.address,
        tus.address,
        interestStrategy,
        priceOracle.address
      )
      .then((tx) => tx.wait());
    await voyage
      .setLiquidationBonus(crab.address, 10500)
      .then((tx) => tx.wait());
    await voyage
      .setIncomeRatio(crab.address, 0.5 * 1e4)
      .then((tx) => tx.wait());
    await voyage
      .setLoanParams(crab.address, 30, 90, 10)
      .then((tx) => tx.wait());
  }
  if (!activated) {
    await voyage.activateReserve(crab.address).then((tx) => tx.wait());
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

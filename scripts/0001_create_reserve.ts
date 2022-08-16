import { Voyage } from '@contracts';
import { ContractTransaction } from 'ethers';
import { ethers, deployments } from 'hardhat';
import { log } from '../helpers/logger';

const getAddress = (contract: string) =>
  deployments.get(contract).then(({ address }) => address);

async function main() {
  const interestStrategy = await getAddress(
    'DefaultReserveInterestRateStrategy'
  );
  const voyage = await ethers.getContract<Voyage>('Voyage');
  const weth = await ethers.getContract('WETH9');
  const crab = await ethers.getContract('Crab');
  const priceOracle = await ethers.getContract('PriceOracle');

  const [initialized, activated] = await voyage.getReserveStatus(crab.address);
  log.info('initialized: %s', initialized);
  log.info('activated: %s', activated);
  let tx: ContractTransaction;
  if (!initialized) {
    await voyage
      .initReserve(
        crab.address,
        weth.address,
        interestStrategy,
        priceOracle.address
      )
      .then((tx) => tx.wait());
    log.info('initialised reserve');
  }
  await voyage.setLiquidationBonus(crab.address, 10500).then((tx) => tx.wait());
  log.info('setLiquidationBonus');
  await voyage.setIncomeRatio(crab.address, 0.5 * 1e4).then((tx) => tx.wait());
  log.info('setIncomeRatio');
  await voyage.setLoanParams(crab.address, 30, 90, 10).then((tx) => tx.wait());
  log.info('setLoanParams');
  if (!activated) {
    await voyage.activateReserve(crab.address).then((tx) => tx.wait());
    log.info('activateReserve');
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

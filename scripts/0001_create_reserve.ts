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
  const priceOracle = await ethers.getContract('PriceOracle');
  const collection = '0x6C5AE80Bcf0Ec85002FE8eb3Ce267232614127C0';

  const [initialized, activated] = await voyage.getReserveStatus(collection);
  log.info('initialized: %s', initialized);
  log.info('activated: %s', activated);
  let tx: ContractTransaction;
  if (!initialized) {
    await voyage
      .initReserve(
        collection,
        weth.address,
        interestStrategy,
        priceOracle.address
      )
      .then((tx) => tx.wait());
    log.info('initialised reserve');
  }
  await voyage.setLiquidationBonus(collection, 10500).then((tx) => tx.wait());
  log.info('setLiquidationBonus');
  await voyage.setIncomeRatio(collection, 0.5 * 1e4).then((tx) => tx.wait());
  log.info('setIncomeRatio');
  await voyage.setLoanParams(collection, 30, 90, 10).then((tx) => tx.wait());
  log.info('setLoanParams');
  if (!activated) {
    await voyage.activateReserve(collection).then((tx) => tx.wait());
    log.info('activateReserve');
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

import { Voyage } from '@contracts';
import {
  BASE_RATE,
  EPOCH,
  GRACE_PERIOD,
  INCOME_RATIO,
  LIQUIDATION_BONUS,
  OPTIMAL_LIQUIDITY_RATIO,
  PROTOCOL_FEE,
  STALENESS,
  TENURE,
} from '@helpers/configuration';
import { ReserveConfiguration } from '@helpers/setupTestSuite';
import { getTreasury, getWETH9 } from '@helpers/task-helpers/addresses';
import { task, types } from 'hardhat/config';

task('dev:configurator-initialize-reserve', 'Initializes a reserve.')
  .addOptionalParam(
    'collection',
    'The collections to initialize. Defaults to Mock Crab'
  )
  .addOptionalParam(
    'currency',
    'The currency that this collection supports. Defaults to mock weth'
  )
  .addOptionalParam(
    'liquidationBonus',
    'Liquidation bonus in basis points.',
    LIQUIDATION_BONUS,
    types.int
  )
  .addOptionalParam(
    'incomeRatio',
    'The senior tranche income allocation in basis points.',
    INCOME_RATIO,
    types.int
  )
  .addOptionalParam(
    'optimalLiquidityRatio',
    'The optimal senior:junior tranche liquidity in basis points.',
    OPTIMAL_LIQUIDITY_RATIO,
    types.int
  )
  .addOptionalParam(
    'staleness',
    'The maximum staleness. Defaults to 48 hours.',
    STALENESS,
    types.int
  )
  .addOptionalParam('epoch', 'Repayment interval.', EPOCH, types.int)
  .addOptionalParam('tenure', 'The loan tenure.', TENURE, types.int)
  .addOptionalParam('grace', 'The grace period.', GRACE_PERIOD, types.int)
  .addOptionalParam(
    'protocolFee',
    'The protocol fee expressed in basis points.',
    PROTOCOL_FEE,
    types.int
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const mc = await ethers.getContract('Crab');
    const weth = await getWETH9();
    const interestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const oracle = await ethers.getContract('PriceOracle');
    const {
      collection = mc.address,
      currency = await getWETH9(),
      tenure,
      epoch,
      grace,
      liquidationBonus,
      incomeRatio,
      optimalLiquidityRatio,
      protocolFee,
      treasury = await getTreasury(),
      floorPrice,
      staleness,
    } = params;
    const [initialized, activated] = await voyage.getReserveStatus(collection);
    console.log(
      `status -- initialized: ${initialized} activated: ${activated}`
    );
    if (!initialized) {
      const reserveConfiguration: ReserveConfiguration = {
        collection: collection,
        currency: currency,
        interestRateStrategyAddress: interestRateStrategy.address,
        priceOracle: oracle.address,
        liquidationBonus: liquidationBonus,
        incomeRatio: incomeRatio,
        optimalLiquidityRatio: optimalLiquidityRatio,
        epoch: epoch,
        term: tenure,
        gracePeriod: grace,
        protocolFee: protocolFee,
        maxTwapStaleness: staleness,
        baseRate: BASE_RATE.toString(),
        treasury: treasury,
        marketplaces: [],
        adapters: [],
      };
      const configurator = await ethers.getContract(
        'VoyageReserveConfigurator'
      );
      await configurator.initReserves([reserveConfiguration]);
    }
  });

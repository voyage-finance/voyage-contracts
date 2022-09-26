import { Voyage } from '@contracts';
import { ReserveConfiguration } from '@helpers/setupTestSuite';
import { getTreasury, getWETH9 } from '@helpers/task-helpers/addresses';
import { task,types } from 'hardhat/config';
//hardhat --network goerli dev:configure-configurator

task('dev:configurator-initialize-reserve', 'Initializes a reserve.')
  .addOptionalParam('collection', 'The collections to initialize. Defaults to Mock Crab')
  .addOptionalParam('currency', 'The currency that this collection supports. Defaults to mock weth')
  .addOptionalParam(
    'liquidationBonus',
    'Liquidation bonus in basis points.',
    10500,
    types.int
  )
  .addOptionalParam(
    'incomeRatio',
    'The senior tranche income allocation in basis points.',
    5000,
    types.int
  )
  .addOptionalParam(
    'optimalLiquidityRatio',
    'The optimal senior:junior tranche liquidity in basis points.',
    50000,
    types.int
  )
  .addOptionalParam(
    'staleness',
    'The maximum staleness. Defaults to 48 hours.',
    48 * 60 * 60,
    types.int
  )
  .addOptionalParam('epoch', 'Repayment interval.', 30, types.int)
  .addOptionalParam('tenure', 'The loan tenure.', 90, types.int)
  .addOptionalParam('grace', 'The grace period.', 7, types.int)
  .addOptionalParam(
    'protocolFee',
    'The protocol fee expressed in basis points.',
    100,
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
        baseRate: 0.2,
        treasury: treasury,
        marketplaces: [],
        adapters: [],
      };
      const configurator = await ethers.getContract('VoyageReserveConfigurator');
      await configurator.initReserves([reserveConfiguration]);
    }
   
  });

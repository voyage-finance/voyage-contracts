import { Voyage } from '@contracts';
import { INCOME_RATIO, LIQUIDATION_BONUS, OPTIMAL_LIQUIDITY_RATIO, PROTOCOL_FEE,TENURE,EPOCH,GRACE_PERIOD,STALENESS } from '@helpers/configuration';
import { getWETH9 } from '@helpers/task-helpers/addresses';
import { setTwap } from '@helpers/task-helpers/configuration';
import { task, types } from 'hardhat/config';

task('dev:initialize-reserve', 'Initializes a reserve.')
  .addOptionalParam(
    'collection',
    'The collections to initialize. Defaults to Mock Crab'
  )
  .addOptionalParam('tenure', 'The loan tenure.', TENURE, types.int)
  .addOptionalParam('epoch', 'Repayment interval.', EPOCH, types.int)
  .addOptionalParam('grace', 'The grace period.', GRACE_PERIOD, types.int)
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
    'protocolFee',
    'The protocol fee expressed in basis points.',
    PROTOCOL_FEE,
    types.int
  )
  .addOptionalParam(
    'floorPrice',
    'The collection floor price',
    '0.5',
    types.string
  )
  .addOptionalParam(
    'staleness',
    'The maximum staleness. Defaults to 48 hours.',
    STALENESS,
    types.int
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const mc = await ethers.getContract('Crab');
    const weth = await getWETH9();
    const interestRateStrategy = await ethers.getContract(
      'DefaultReserveInterestRateStrategy'
    );
    const oracle = await ethers.getContract('PriceOracle');
    const {
      collection = mc.address,
      tenure,
      epoch,
      grace,
      liquidationBonus,
      incomeRatio,
      optimalLiquidityRatio,
      protocolFee,
      floorPrice,
      staleness,
    } = params;
    const [initialized, activated] = await voyage.getReserveStatus(collection);

    console.log(
      `status -- initialized: ${initialized} activated: ${activated}`
    );

    if (!initialized) {
      await voyage
        .initReserve(
          collection,
          weth,
          interestRateStrategy.address,
          oracle.address
        )
        .then((tx) => tx.wait());
      console.log(`Initialized reserve ${collection}`);
    }

    await voyage
      .setLiquidationBonus(collection, liquidationBonus)
      .then((tx) => tx.wait());
    console.log(`setLiquidationBonus: ${liquidationBonus}`);
    await voyage
      .setIncomeRatio(collection, incomeRatio)
      .then((tx) => tx.wait());
    console.log(`setIncomeRatio: ${incomeRatio}`);
    await voyage
      .setLoanParams(collection, epoch, tenure, grace)
      .then((tx) => tx.wait());
    await voyage
      .setOptimalLiquidityRatio(collection, optimalLiquidityRatio)
      .then((tx) => tx.wait());
    await voyage.setMaxTwapStaleness(
      collection,
      ethers.BigNumber.from(staleness)
    );

    console.log(`set reserve params:
    - epoch: ${epoch}
    - tenure: ${tenure}
    - gracePeriod: ${grace}
    - optimalLiquidityRatio: ${optimalLiquidityRatio}
    - max staleness: ${staleness}
    `);

    if (!activated) {
      await voyage.activateReserve(mc.address).then((tx) => tx.wait());
    }

    await voyage.updateProtocolFee(owner, protocolFee).then((tx) => tx.wait());
    console.log(`Set ${collection} protocol fee to ${protocolFee}.\n`);

    // set twap
    await setTwap({
      collection,
      twap: hre.ethers.utils.parseEther(floorPrice),
    });
    console.log(`Set ${collection} floor price to ${floorPrice}. \n`);
  });

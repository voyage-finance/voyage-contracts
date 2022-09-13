import { Voyage } from '@contracts';
import { setTwap } from '@helpers/task-helpers/configuration';
import { task, types } from 'hardhat/config';

task('dev:initialize-reserve', 'Initializes a reserve.')
  .addOptionalParam(
    'collection',
    'The collections to initialize. Defaults to Mock Crab'
  )
  .addOptionalParam('tenure', 'The loan tenure.', 90, types.int)
  .addOptionalParam('epoch', 'Repayment interval.', 30, types.int)
  .addOptionalParam('grace', 'The grace period.', 7, types.int)
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
    'protocolFee',
    'The protocol fee expressed in basis points.',
    100,
    types.int
  )
  .addOptionalParam(
    'floorPrice',
    'The collection floor price',
    '0.5',
    types.string
  )
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const { owner } = await hre.getNamedAccounts();
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const mc = await ethers.getContract('Crab');
    const weth = await ethers.getContract('WETH9');
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
    } = params;
    const [initialized, activated] = await voyage.getReserveStatus(collection);

    console.log(
      `status -- initialized: ${initialized} activated: ${activated}`
    );

    if (!initialized) {
      await voyage
        .initReserve(
          collection,
          weth.address,
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
      ethers.BigNumber.from(24 * 60 * 60)
    );
    await voyage.updateProtocolFee(owner, protocolFee).then((tx) => tx.wait());

    console.log(`setLoanParams: 
- epoch: ${epoch}
- tenure: ${tenure}
- gracePeriod: ${grace}
- optimalLiquidityRatio: ${optimalLiquidityRatio}
- protocolFee: ${protocolFee}
`);

    if (!activated) {
      await voyage.activateReserve(mc.address).then((tx) => tx.wait());
    }

    // set twap
    await setTwap({
      collection,
      twap: hre.ethers.utils.parseEther(floorPrice),
    });
    console.log(`Set floor price for ${collection} to ${floorPrice}`);
  });

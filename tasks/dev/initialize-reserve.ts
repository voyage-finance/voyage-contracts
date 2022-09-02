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
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
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
    } = params;
    const [initialized, activated] = await voyage.getReserveStatus(collection);

    console.log(
      `status -- initialized: ${initialized} activated: ${activated}`
    );

    if (!initialized) {
      await voyage
        .initReserve(
          mc.address,
          weth.address,
          interestRateStrategy.address,
          oracle.address
        )
        .then((tx) => tx.wait());
      console.log('initialized reserve');
    }

    await voyage
      .setLiquidationBonus(mc.address, liquidationBonus)
      .then((tx) => tx.wait());
    console.log(`setLiquidationBonus: ${liquidationBonus}`);
    await voyage
      .setIncomeRatio(mc.address, incomeRatio)
      .then((tx) => tx.wait());
    console.log(`setIncomeRatio: ${incomeRatio}`);
    await voyage
      .setLoanParams(mc.address, epoch, tenure, grace)
      .then((tx) => tx.wait());
    console.log(`setLoanParams: 
- epoch: ${epoch}
- tenure: ${tenure}
- gracePeriod: ${grace}`);

    if (!activated) {
      await voyage.activateReserve(mc.address).then((tx) => tx.wait());
    }

    // set twap
    await setTwap({ collection, twap: hre.ethers.utils.parseEther('0.0001') });
  });

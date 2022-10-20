import { Voyage } from '@contracts';
import { TENURE, EPOCH, GRACE_PERIOD } from '@helpers/configuration';
import { task, types } from 'hardhat/config';

task('dev:set-loan-params', 'Initializes a reserve.')
  .addOptionalParam(
    'collection',
    'The collections to initialize. Defaults to Mock Crab'
  )
  .addOptionalParam('tenure', 'The loan tenure.', TENURE, types.int)
  .addOptionalParam('epoch', 'Repayment interval.', EPOCH, types.int)
  .addOptionalParam('grace', 'The grace period.', GRACE_PERIOD, types.int)
  .setAction(async (params, hre) => {
    await hre.run('set-hre');
    const { ethers } = hre;
    const voyage = await ethers.getContract<Voyage>('Voyage');
    const mc = await ethers.getContract('Crab');
    const { collection = mc.address, tenure, epoch, grace } = params;
    const [initialized, activated] = await voyage.getReserveStatus(collection);

    console.log(
      `status -- initialized: ${initialized} activated: ${activated}`
    );
    await voyage
      .setLoanParams(collection, epoch, tenure, grace)
      .then((tx) => tx.wait());
  });

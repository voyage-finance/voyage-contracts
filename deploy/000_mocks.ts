import { getWETH9 } from '@helpers/task-helpers/addresses';
import { isHardhat } from '@helpers/task-helpers/chain';
import { DeployFunction } from 'hardhat-deploy/types';

const deployFn: DeployFunction = async (hre) => {
  if (!isHardhat()) {
    console.log('Not hardhat, skipping mock deployments.');
    return;
  }
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  await deploy('WETH9', {
    from: owner,
    log: true,
  });

  await deploy('MockForwarder', {
    from: owner,
    log: true,
  });

  await deploy('Crab', {
    from: owner,
    log: true,
    args: ['Mocked Crab', 'MC'],
  });

  const weth9 = await getWETH9();

  await deploy('MockMarketPlace', {
    from: owner,
    args: [weth9],
    log: true,
  });

  await deploy('MockSeaport', {
    from: owner,
    log: true,
  });
};

deployFn.tags = ['Mocks'];

export default deployFn;

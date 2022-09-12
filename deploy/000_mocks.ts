import { DeployFunction } from 'hardhat-deploy/types';

const deployFn: DeployFunction = async (hre) => {
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

  await deploy('MockMarketPlace', {
    from: owner,
    log: true,
  });

  await deploy('MockSeaport', {
    from: owner,
    log: true,
  });
};

deployFn.tags = ['Mocks'];

export default deployFn;

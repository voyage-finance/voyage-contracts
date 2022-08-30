import BigNumber from 'bignumber.js';
import { DeployFunction } from 'hardhat-deploy/types';

const WRM_NAME = 'WadRayMath';
const INTEREST_STRATEGY_NAME = 'DefaultReserveInterestRateStrategy';

const RAY = new BigNumber(10).pow(27);

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  if (network.name !== 'avalancheMain') {
    await deploy('Crab', {
      from: owner,
      log: true,
      args: ['Mocked Crab', 'MC'],
    });
  }

  await deploy('MockMarketPlace', {
    from: owner,
    log: true,
    args: [],
  });
  await deploy('MockSeaport', {
    from: owner,
    log: true,
    args: [],
  });

  const wadRayMath = await deploy(WRM_NAME, { from: owner, log: true });

  const utilisationRate = new BigNumber('0.8').multipliedBy(RAY).toFixed();
  const slope = new BigNumber('0.04').multipliedBy(RAY).toFixed();
  const baseInterest = new BigNumber('0.18').multipliedBy(RAY).toFixed();

  await deploy(INTEREST_STRATEGY_NAME, {
    from: owner,
    log: true,
    libraries: { WadRayMath: wadRayMath.address },
    args: [utilisationRate, slope, baseInterest],
  });
};

deployFn.dependencies = ['Voyage'];
deployFn.tags = ['Tokenization'];

export default deployFn;

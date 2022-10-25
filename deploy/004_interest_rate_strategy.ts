import { RAY } from '@helpers/constants';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  const utilisationRate = ethers.BigNumber.from(8).mul(RAY).div(10);
  const slope = ethers.BigNumber.from(4).mul(RAY).div(100);
  const baseInterest = ethers.BigNumber.from(2).mul(RAY).div(10);

  const wrm = await deploy('WadRayMath', { from: owner, log: true });
  await deploy('DefaultReserveInterestRateStrategy', {
    from: owner,
    log: true,
    libraries: { WadRayMath: wrm.address },
    args: [utilisationRate, slope, baseInterest],
  });
};

main.tags = ['InterestRateStrategy'];

export default main;

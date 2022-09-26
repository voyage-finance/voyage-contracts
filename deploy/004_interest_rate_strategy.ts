import { RAY } from '@helpers/constants';
import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  // 0.6
  const utilisationRate = ethers.BigNumber.from(6).mul(RAY).div(10);
  // 1
  const slope = ethers.BigNumber.from(100).mul(RAY).div(100);
  // 0.5214286714290
  const baseInterest = ethers.BigNumber.from(521428671429)
    .mul(RAY)
    .div(1000000000000);

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

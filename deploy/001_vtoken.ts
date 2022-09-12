import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  await deploy('JuniorDepositToken', {
    from: owner,
    log: true,
  });

  await deploy('SeniorDepositToken', {
    from: owner,
    log: true,
  });
};

main.tags = ['VToken'];

export default main;

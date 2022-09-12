import { getWETH9 } from '@helpers/task-helpers/addresses';
import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  const weth9 = await getWETH9();
  await deploy('LooksRareAdapter', {
    from: owner,
    log: true,
  });
  await deploy('SeaportAdapter', {
    from: owner,
    log: true,
    args: [weth9],
  });
};

main.tags = ['Adapters'];

export default main;

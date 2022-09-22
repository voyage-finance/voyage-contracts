import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();
  const voyage = await ethers.getContract('Voyage');
  await deploy('VoyageReserveConfigurator', {
    from: owner,
    log: true,
    args: [voyage.address],
  });
};

main.tags = ['Configurator'];
main.dependencies = ['Diamond', 'Facets'];

export default main;

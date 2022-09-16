import { DeployFunction } from 'hardhat-deploy/types';

const main: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  await deploy('Vault', {
    from: owner,
    log: true,
  });
};

main.tags = ['Vault'];

export default main;

import { DeployFunction } from 'hardhat-deploy/types';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();
  await deploy('AddressResolver', {
    from: owner,
    args: [],
    log: true,
  });
};

deployFn.tags = ['AddressResolver'];

export default deployFn;

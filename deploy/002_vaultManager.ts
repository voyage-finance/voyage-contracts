import { DeployFunction } from 'hardhat-deploy/types';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  const AddressResolver = await deployments.get('AddressResolver');
  const Voyager = await deployments.get('Voyager');

  const VaultFactory = await deploy('VaultFactory', {
    from: owner,
    log: true,
  });

  const VaultManagerProxy = await deploy('VaultManagerProxy', {
    from: owner,
    args: [AddressResolver.address],
    log: true,
  });

  const VaultManager = await deploy('VaultManager', {
    from: owner,
    args: [
      VaultManagerProxy.address,
      AddressResolver.address,
      Voyager.address,
      VaultFactory.address,
    ],
    log: true,
  });

  const VaultStorage = await deploy('VaultStorage', {
    from: owner,
    args: [VaultManager.address],
    log: true,
  });

  await execute(
    'VaultManagerProxy',
    { from: owner, log: true },
    'setTarget',
    VaultManager.address
  );
};

deployFn.dependencies = ['AddressResolver', 'Voyager'];
deployFn.tags = ['VaultManager'];

export default deployFn;

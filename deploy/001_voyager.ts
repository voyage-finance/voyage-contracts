import { DeployFunction } from 'hardhat-deploy/types';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  await deploy('Voyager', {
    from: owner,
    args: [owner],
    log: true,
  });

  const AddressResolver = await deployments.get('AddressResolver');

  await execute(
    'Voyager',
    { from: owner },
    'setAddressResolverAddress',
    AddressResolver.address
  );
};

deployFn.dependencies = ['AddressResolver'];
deployFn.tags = ['Voyager'];

export default deployFn;

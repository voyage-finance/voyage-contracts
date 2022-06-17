import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { execute } = deployments;
  const { owner } = await getNamedAccounts();

  const Voyager = await deployments.get('Voyager');
  let AclManager = await deployments.get('ACLManager');
  let ExtCallAclProxy = await deployments.get('ExtCallACLProxy');

  const names = [
    ethers.utils.formatBytes32String('voyager'),
    ethers.utils.formatBytes32String('aclManager'),
    ethers.utils.formatBytes32String('extCallACLProxy'),
  ];
  const destinations = [
    Voyager.address,
    AclManager.address,
    ExtCallAclProxy.address,
  ];
  await execute(
    'AddressResolver',
    { from: owner, log: true },
    'importAddresses',
    names,
    destinations
  );
};

deployFn.tags = ['SetAddressResolver'];
deployFn.dependencies = [
  'Voyager',
  'AddressResolver',
  'ExtCallAcl',
  'ACLManager',
];

export default deployFn;

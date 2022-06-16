import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { execute } = deployments;
  const { owner } = await getNamedAccounts();

  const Voyager = await deployments.get('Voyager');
  let AclManager = await deployments.get('ACLManager');
  let ExtCallAclProxy = await deployments.get('ExtCallACLProxy');
  let VaultManagerProxy = await deployments.get('VaultManagerProxy');
  let VaultManager = await deployments.get('VaultManager');
  let VaultStorage = await deployments.get('VaultStorage');

  const names = [
    ethers.utils.formatBytes32String('voyager'),
    ethers.utils.formatBytes32String('aclManager'),
    ethers.utils.formatBytes32String('extCallACLProxy'),
    ethers.utils.formatBytes32String('vaultManagerProxy'),
    ethers.utils.formatBytes32String('vaultManager'),
    ethers.utils.formatBytes32String('vaultStorage'),
  ];
  const destinations = [
    Voyager.address,
    AclManager.address,
    ExtCallAclProxy.address,
    VaultManagerProxy.address,
    VaultManager.address,
    VaultStorage.address,
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
  'VaultManager',
  'ExtCallAcl',
  'ACLManager',
];

export default deployFn;

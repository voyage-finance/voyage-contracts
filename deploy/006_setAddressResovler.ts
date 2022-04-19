import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const ACLMANAGER_NAME = 'ACLManager';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  let LMProxy = await deployments.get('LiquidityManagerProxy');
  let LM = await deployments.get('LiquidityManager');
  let LMStorage = await deployments.get('LiquidityManagerStorage');
  let AclManager = await deployments.get('ACLManager');
  let ExtCallAclProxy = await deployments.get('ExtCallACLProxy');
  let VaultManagerProxy = await deployments.get('VaultManagerProxy');
  let VaultManager = await deployments.get('VaultManager');
  let VaultStorage = await deployments.get('VaultStorage');

  const names = [
    ethers.utils.formatBytes32String('liquidityManagerProxy'),
    ethers.utils.formatBytes32String('liquidityManager'),
    ethers.utils.formatBytes32String('liquidityManagerStorage'),
    ethers.utils.formatBytes32String('aclManager'),
    ethers.utils.formatBytes32String('extCallACLProxy'),
    ethers.utils.formatBytes32String('vaultManagerProxy'),
    ethers.utils.formatBytes32String('vaultManager'),
    ethers.utils.formatBytes32String('vaultStorage'),
  ];
  const destinations = [
    LMProxy.address,
    LM.address,
    LMStorage.address,
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
  'AddressResolver',
  'VaultManager',
  'LiquidityManager',
  'ExtCallAcl',
  'ACLManager',
];

export default deployFn;

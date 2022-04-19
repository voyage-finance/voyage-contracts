import { DeployFunction } from 'hardhat-deploy/types';

const ACLMANAGER_NAME = 'ACLManager';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  const VaultManager = await deployments.get('VaultManager');

  await deploy(ACLMANAGER_NAME, {
    from: owner,
    args: [owner],
    log: true,
  });

  await execute(
    'ACLManager',
    { from: owner, log: true },
    'grantLiquidityManager',
    owner
  );

  await execute(
    'ACLManager',
    { from: owner, log: true },
    'grantVaultManager',
    owner
  );

  await execute(
    'ACLManager',
    { from: owner, log: true },
    'grantPoolManager',
    owner
  );

  await execute(
    'ACLManager',
    { from: owner, log: true },
    'grantVaultManagerContract',
    VaultManager.address
  );
};

deployFn.tags = ['ACLManager'];
deployFn.dependencies = ['VaultManager'];

export default deployFn;

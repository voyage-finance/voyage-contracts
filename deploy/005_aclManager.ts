import { DeployFunction } from 'hardhat-deploy/types';

const ACLMANAGER_NAME = 'ACLManager';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute } = deployments;
  const { owner } = await getNamedAccounts();

  await deploy(ACLMANAGER_NAME, {
    from: owner,
    args: [owner],
    log: true,
  });

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
    'grantOracleManager',
    owner
  );
};

deployFn.tags = ['ACLManager'];
deployFn.dependencies = ['VaultManager'];

export default deployFn;

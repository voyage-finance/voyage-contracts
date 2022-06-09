import { DeployFunction } from 'hardhat-deploy/types';

const LM_PROXY_NAME = 'LiquidityManagerProxy';
const LM_NAME = 'LiquidityManager';
const RESERVE_LOGIC_NAME = 'ReserveLogic';
const DEBT_LOGIC_NAME = 'DebtLogic';
const VALIDATION_LOGIC_NAME = 'ValidationLogic';
const LM_STORAGE_NAME = 'LiquidityManagerStorage';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, read, execute } = deployments;
  const { owner } = await getNamedAccounts();

  const Voyager = await deployments.get('Voyager');

  const LMProxy = await deploy(LM_PROXY_NAME, { from: owner, log: true });

  const ReserveLogic = await deploy(RESERVE_LOGIC_NAME, {
    from: owner,
    log: true,
  });

  const DebtLogic = await deploy(DEBT_LOGIC_NAME, {
    from: owner,
    log: true,
  });

  const ValidationLogic = await deploy(VALIDATION_LOGIC_NAME, {
    from: owner,
    log: true,
  });

  const LiquidityManager = await deploy(LM_NAME, {
    from: owner,
    args: [LMProxy.address, Voyager.address],
    libraries: {
      ReserveLogic: ReserveLogic.address,
    },
    log: true,
  });

  await deploy(LM_STORAGE_NAME, {
    from: owner,
    args: [LiquidityManager.address],
    libraries: {
      ReserveLogic: ReserveLogic.address,
      DebtLogic: DebtLogic.address,
      ValidationLogic: ValidationLogic.address,
    },
    log: true,
  });

  const lmProxyOwner = await read(LM_PROXY_NAME, { from: owner }, 'owner');

  const isOwner = lmProxyOwner === owner;

  if (isOwner) {
    await execute(
      LM_PROXY_NAME,
      { from: owner, log: true },
      'setTarget',
      LiquidityManager.address
    );
  }
};

deployFn.dependencies = ['Voyager'];
deployFn.tags = [LM_NAME];

export default deployFn;

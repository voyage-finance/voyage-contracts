import { DeployFunction } from 'hardhat-deploy/types';

const LM_PROXY_NAME = 'LiquidityManagerProxy';
const LM_NAME = 'LiquidityManager';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, read, execute } = deployments;
  const { owner } = await getNamedAccounts();

  const Voyager = await deployments.get('Voyager');

  let LMProxy = await deployments.getOrNull(LM_PROXY_NAME);
  if (!LMProxy) {
    LMProxy = await deploy(LM_PROXY_NAME, { from: owner, log: true });
  }

  const LiquidityManager = await deploy(LM_NAME, {
    from: owner,
    args: [LMProxy.address, Voyager.address],
    log: true,
  });

  const isOwner = await read(LM_PROXY_NAME, { from: owner }, 'isOwner');

  if (isOwner) {
    await execute(
      LM_PROXY_NAME,
      { from: owner },
      'setTarget',
      LiquidityManager.address
    );
  }
};

deployFn.dependencies = ['Voyager'];
deployFn.tags = [LM_NAME];

export default deployFn;

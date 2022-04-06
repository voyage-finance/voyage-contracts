import { ethers } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';
import { LiquidityManager } from '../typechain';

const LM_PROXY_NAME = 'LiquidityManagerProxy';
const LM_NAME = 'LiquidityManager';
const LM_STORAGE_NAME = 'LiquidityManagerStorage';
const RESERVE_LOGIC_NAME = 'ReserveLogic';
const VALIDATION_LOGIC_NAME = 'ValidationLogic';

const deployFn: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();

  const ReserveLogic = await deploy(RESERVE_LOGIC_NAME, {
    from: owner,
    log: true,
  });
  const ValidationLogic = await deploy(VALIDATION_LOGIC_NAME, {
    from: owner,
    log: true,
  });

  const LM = await deployments.get(LM_NAME);
  const LMProxy = await deployments.get(LM_PROXY_NAME);
  const LMStorage = await deploy(LM_STORAGE_NAME, {
    from: owner,
    args: [LM.address],
    libraries: {
      ReserveLogic: ReserveLogic.address,
      ValidationLogic: ValidationLogic.address,
    },
    log: true,
  });

  const names = [
    ethers.utils.formatBytes32String('liquidityManagerProxy'),
    ethers.utils.formatBytes32String('liquidityManager'),
    ethers.utils.formatBytes32String('liquidityManagerStorage'),
  ];
  const destinations = [LMProxy.address, LM.address, LMStorage.address];

  // TODO: only execute this txn when LMStorage, LMProxy or LM have changed
  await execute(
    'AddressResolver',
    { from: owner, log: true },
    'importAddresses',
    names,
    destinations
  );

  const Voyager = await deployments.get('Voyager');
  const isOwner = await read(LM_PROXY_NAME, { from: owner }, 'isOwner');
  if (isOwner) {
    await execute(
      LM_PROXY_NAME,
      { from: owner },
      'transferOwnership',
      Voyager.address
    );
    await execute(
      'Voyager',
      { from: owner },
      'claimLiquidityManagerProxyOwnership'
    );
  }
};

deployFn.dependencies = ['AddressResolver', LM_NAME, 'Voyager'];
deployFn.tags = [LM_STORAGE_NAME];

export default deployFn;

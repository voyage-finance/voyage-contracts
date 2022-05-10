import { DeployFunction } from 'hardhat-deploy/types';
import { DefaultHealthStrategy, Tus } from '@contracts';
import TusABI from '../artifacts/contracts/mock/Tus.sol/Tus.json';
import { ethers } from 'hardhat';
import BigNumber from 'bignumber.js';

const LM_NAME = 'LiquidityManager';
const LM_STORAGE_NAME = 'LiquidityManagerStorage';
const JR_TOKEN_NAME = 'JuniorDepositToken';
const SR_TOKEN_NAME = 'SeniorDepositToken';
const DEBT_TOKEN_NAME = 'StableDebtToken';
const WRM_NAME = 'WadRayMath';
const INTEREST_STRATEGY_NAME = 'DefaultReserveInterestRateStrategy';
const HEALTH_STRATEGY_ADDRESS = 'DefaultHealthStrategy';

const RAY = new BigNumber(10).pow(27);

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();
  const signer = ethers.provider.getSigner(0);

  let TreasureUnderSea: Tus;
  const tusSupply = new BigNumber(1_000_000_000).multipliedBy(
    new BigNumber(10).pow(18)
  );
  if (network.live && network.name === 'avalancheMain') {
    TreasureUnderSea = new ethers.Contract(
      process.env.TUS || '0x0',
      TusABI.abi,
      signer
    ) as Tus;
  } else {
    const TusDeployment = await deploy('Tus', {
      from: owner,
      log: true,
      args: [tusSupply.toFixed()],
    });
    TreasureUnderSea = new ethers.Contract(
      TusDeployment.address,
      TusDeployment.abi,
      signer
    ) as Tus;
  }
  const AddressResolver = await deployments.get('AddressResolver');
  const tusInitArgs = await Promise.all([
    TreasureUnderSea.address,
    TreasureUnderSea.decimals(),
    TreasureUnderSea.name(),
    TreasureUnderSea.symbol(),
  ]);
  const JuniorDepositToken = await deploy(JR_TOKEN_NAME, {
    from: owner,
    log: true,
  });
  const SeniorDepositToken = await deploy(SR_TOKEN_NAME, {
    from: owner,
    log: true,
  });

  if (!(await read(JR_TOKEN_NAME, 'isInitialized'))) {
    await execute(
      JR_TOKEN_NAME,
      { from: owner, log: true },
      'initialize',
      AddressResolver.address,
      ...tusInitArgs,
      ethers.utils.formatBytes32String('')
    );
  }

  if (!(await read(SR_TOKEN_NAME, 'isInitialized'))) {
    await execute(
      SR_TOKEN_NAME,
      { from: owner, log: true },
      'initialize',
      AddressResolver.address,
      ...tusInitArgs,
      ethers.utils.formatBytes32String('')
    );
  }

  const StableDebtToken = await deploy('StableDebtToken', {
    from: owner,
    log: true,
  });
  if (!(await read(DEBT_TOKEN_NAME, 'isInitialized'))) {
    await execute(
      DEBT_TOKEN_NAME,
      { from: owner, log: true },
      'initialize',
      ...tusInitArgs,
      AddressResolver.address,
      ethers.utils.formatBytes32String('')
    );
  }

  const WadRayMath = await deploy(WRM_NAME, { from: owner, log: true });

  const utilisationRate = new BigNumber('0.8').multipliedBy(RAY).toFixed();
  const slope1 = new BigNumber('0.04').multipliedBy(RAY).toFixed();
  const slope2 = new BigNumber('1').multipliedBy(RAY).toFixed();
  const baseInterest = new BigNumber('0.18').multipliedBy(RAY).toFixed();

  await deploy(INTEREST_STRATEGY_NAME, {
    from: owner,
    log: true,
    libraries: { WadRayMath: WadRayMath.address },
    args: [utilisationRate, slope1, slope2, baseInterest],
  });

  await deploy(HEALTH_STRATEGY_ADDRESS, {
    from: owner,
    log: true,
    libraries: { WadRayMath: WadRayMath.address },
    // 5, 5, 2,8
    args: [
      '5000000000000000000000000000',
      '5000000000000000000000000000',
      '2000000000000000000000000000',
      '8000000000000000000000000000',
    ],
  });

  const names = [
    ethers.utils.formatBytes32String('stableDebtToken'),
    ethers.utils.formatBytes32String('juniorDepositToken'),
    ethers.utils.formatBytes32String('seniorDepositToken'),
  ];
  const destinations = [
    StableDebtToken.address,
    JuniorDepositToken.address,
    SeniorDepositToken.address,
  ];
  await execute(
    'AddressResolver',
    { from: owner, log: true },
    'importAddresses',
    names,
    destinations
  );
};

deployFn.dependencies = [
  'AddressResolver',
  'Voyager',
  LM_NAME,
  LM_STORAGE_NAME,
];
deployFn.tags = ['Tokenization'];

export default deployFn;

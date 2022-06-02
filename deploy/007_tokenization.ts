import { DeployFunction } from 'hardhat-deploy/types';
import { LiquidityManager, Tus } from '@contracts';
import TusABI from '../artifacts/contracts/mock/Tus.sol/Tus.json';
import BigNumber from 'bignumber.js';
import { MAX_UINT_256 } from '../helpers/math';

const LM_NAME = 'LiquidityManager';
const LM_STORAGE_NAME = 'LiquidityManagerStorage';
const JR_TOKEN_NAME = 'JuniorDepositToken';
const SR_TOKEN_NAME = 'SeniorDepositToken';
const WRM_NAME = 'WadRayMath';
const INTEREST_STRATEGY_NAME = 'DefaultReserveInterestRateStrategy';
const HEALTH_STRATEGY_ADDRESS = 'DefaultHealthStrategy';

const RAY = new BigNumber(10).pow(27);

const deployFn: DeployFunction = async (hre) => {
  const { deployments, ethers, getNamedAccounts, network } = hre;
  const { deploy, execute, read } = deployments;
  const { owner } = await getNamedAccounts();

  const tusSupply = new BigNumber(1_000_000_000_000).multipliedBy(
    new BigNumber(10).pow(18)
  );
  if (!network.live && network.name !== 'avalancheMain') {
    await deploy('Tus', {
      from: owner,
      log: true,
      args: [tusSupply.toFixed()],
    });
  }
  const tus = await ethers.getContract<Tus>('Tus');
  const AddressResolver = await deployments.get('AddressResolver');
  const tusInitArgs = await Promise.all([
    tus.address,
    tus.decimals(),
    tus.name(),
    tus.symbol(),
  ]);
  const JuniorDepositToken = await deploy(JR_TOKEN_NAME, {
    from: owner,
    log: true,
    args: [AddressResolver.address, tus.address, 'TUS Junior Tranche', 'jvTUS'],
  });
  const SeniorDepositToken = await deploy(SR_TOKEN_NAME, {
    from: owner,
    log: true,
    args: [AddressResolver.address, tus.address, 'TUS Senior Tranche', 'svTUS'],
  });

  const liquidityManager = await ethers.getContract<LiquidityManager>(
    'LiquidityManager'
  );

  await liquidityManager.approve(
    tus.address,
    SeniorDepositToken.address,
    MAX_UINT_256
  );
  await liquidityManager.approve(
    tus.address,
    JuniorDepositToken.address,
    MAX_UINT_256
  );

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
    ethers.utils.formatBytes32String('juniorDepositToken'),
    ethers.utils.formatBytes32String('seniorDepositToken'),
  ];
  const destinations = [JuniorDepositToken.address, SeniorDepositToken.address];
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
